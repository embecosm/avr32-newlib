
#if __AVR32_UC__ == 3

#define SECURE_FLASH_SIZE           0x400
#define SECURE_RAM_SIZE             0x400
#define SEC_EXE_STATUS_DEFAULT      0x000000AA
#define SEC_EXE_STATUS_INTERRUPTED  0x00000011
#define AVR32_SS_ADRR               0x000001A4
#define AVR32_SS_ADRF               0x000001A0
#define AVR32_SS_RAR                0x000001B8
#define AVR32_SR                    0x00000000
#define AVR32_SS_RSR                0x000001BC
#define AVR32_SS_STATUS             0x0000019C
#define AVR32_SR_GM                 16
#define AVR32_SR_I0M                17


    .section  .reset, "ax", @progbits

    .global _start
    .type _start, @function

  // Secure State Event Handling table.

_start: // reset @ == 0x80000000
    rjmp   __flashvault_boot
.org 0x4  // SSCALL handler entry point
    rjmp   __flashvault_sscall_handle
.org 0x8  // Exceptions handler entry point
    rjmp   __flashvault_exceptions_handle
.org 0xc  // NMI handler entry point
    rjmp   __flashvault_nmi_handle
.org 0x10 // BREAKPOINT handler entry point
    rjmp   __flashvault_bp_handle
.org 0x14 // Interrupts handler entry point
    rjmp   __flashvault_irq_handle


    //** Boot
__flashvault_boot:
    // Set the Secure Sections size to 1kB
    mov    r8, SECURE_FLASH_SIZE
    mtsr   AVR32_SS_ADRR, r8
    mtsr   AVR32_SS_ADRF, r8

    // Init the Secure State Stack pointer
    mov    sp, _estack

    // Init the SS_RAR register to the start address of the zone outside the FlashVault.
    lda.w   r8, __flashvault_user_app_start
    ld.w    r9, r8[0]
    mtsr   AVR32_SS_RAR, r9

    // Init the SS_RSR register to Secure State Inactive (clear the SS bit of the
    // current SR register).
    mfsr   r8, AVR32_SR
    cbr    r8, 31
    mtsr   AVR32_SS_RSR, r8

    // Load initialized data having a global lifetime from the data LMA.
    lda.w  r0, _data
    lda.w  r1, _edata
    cp     r0, r1
    brhs   sec_idata_load_loop_end
    lda.w  r2, _data_lma
sec_idata_load_loop:
    ld.d   r4, r2++
    st.d   r0++, r4
    cp     r0, r1
    brlo   sec_idata_load_loop
sec_idata_load_loop_end:

    // Clear uninitialized data having a global lifetime in the blank static storage section.
    lda.w  r0, __bss_start
    lda.w  r1, _end
    cp     r0, r1
    brhs   sec_udata_clear_loop_end
    mov    r2, 0
    mov    r3, 0
sec_udata_clear_loop:
    st.d   r0++, r2
    cp     r0, r1
    brlo   sec_udata_clear_loop
sec_udata_clear_loop_end:

    // Set the execution status of the secure world as default
    mov    r0, SEC_EXE_STATUS_DEFAULT
    mtsr   AVR32_SS_STATUS, r0

    // Switch to the application outside the FlashVault.
    retss

    // Should never reach this point.


    //** SSCALL handler
    //** R8: public api vector number
__flashvault_sscall_handle:
    // Temporary save of r0 before modifying it.
    st.w --sp, r0
  
    // Check if we're back from an interrupt handling performed in the application
    // outside the FlashVault.
    // If so we should resume the secure execution at the point where it was
    // interrupted.
    mfsr   r0, AVR32_SS_STATUS
    cp     r0, SEC_EXE_STATUS_INTERRUPTED
  
    // Restore r0
    ld.w   r0, sp++
    breq   __flashvault_irq_restore_exe

    // We must save all registers on the stack else the application outside the
    // FlashVault may fail when it resumes!
    pushm  r0-r12, lr

    // Save SS_RAR and SS_RSR in secure memory before enabling IRQ
    mov    r0, ss_rar_save
    mfsr   r1, AVR32_SS_RAR
    st.w   r0[0], r1
    mov    r0, ss_rsr_save
    mfsr   r1, AVR32_SS_RSR
    st.w   r0[0], r1

    // Enable INT0 interrupts.
    csrf   AVR32_SR_GM
    csrf   AVR32_SR_I0M

    // Make sure R8 holds one of the public api vector number
    lda.w   r7, __fv_table
    sub     r5, r7, -128
__fv_table_loop_start:
    ld.w    r6, r7[0]
    cp.w    r6, r8
    brne    __fv_table_next 
    ld.w    r6, r7[4]
    cp.w    r6, 0
    breq    __fv_table_next
    icall   r6
    rjmp   __flashvault_exit
__fv_table_next:
    sub     r7, -8
    cp.w    r7, r5
    brlo    __fv_table_loop_start 
    // Expected fall through to __bad_sscall_handler
 
__bad_sscall_handler:    
    // Go back to the application outside the FlashVault.
    mov    r12, r8
    // Expected fall through to __flashvault_exit()


    //** Common routine to leave the secure mode:
    //** Mask interrupts, restore RAR/RSR. Return value in r12
    //** Use the following addresses (RAR @0(i.e. in ss_rar_save), RSR @4(i.e. in ss_rsr_save))
    //** Cannot use stack since we need random access when handling interrupts.
__flashvault_exit:
    // Disable all interrupts
    ssrf   AVR32_SR_GM

    // Restore RSR
    mov    r0, ss_rsr_save
    ld.w   r1, r0[0]
    mtsr   AVR32_SS_RSR, r1

    // Restore RAR
    mov    r0, ss_rar_save
    ld.w   r1, r0[0]
    sub    r1, -2 // Update return address to the instruction after SSCALL
    mtsr   AVR32_SS_RAR, r1

    // We must restore all registers from the stack else the application outside
    // the FlashVault may fail when it resumes!
    ldm    sp++, r0-r12, lr
    retss


    //** Restore a previously interrupted secure mode execution:
    //** - Set the secure mode execution status back to default
    //** - Restore the SR & PC from the secure stack to resume the secure code execution
__flashvault_irq_restore_exe:

    // Pop SR and PC to interrupted secure mode application SSCALL from stack.
    // Set the secure mode execution status back to default.
    mov    r0, SEC_EXE_STATUS_DEFAULT
    mtsr   AVR32_SS_STATUS, r0

    // Restore the SR & PC from the secure stack.
    // IRQs will then be reenabled due to SR restore.
    // What will happen if IRQ is received immediately? Must this be done atomically?
    ld.w   r0, sp++
    mtsr   AVR32_SR, r0

    // We must restore all registers from the stack else the secure code application
    // will fail when it resumes!
    sub    sp, 15*4           // Reset the SP to the appropriate position before popping R0-R12, LR.
    ldm    sp++, r0-r12, lr
    sub    sp, -1*4           // Reset the SP to the appropriate position before popping SS_RAR.
    ld.w   pc, sp++


    //**  Exceptions handler, NMI handler, breakpoint handler.
__flashvault_exceptions_handle:
__flashvault_nmi_handle:
__flashvault_bp_handle:
    rjmp   $


    //** Interrupts handler:
    //** Secure code was interrupted. Save required state on the secure stack, and
    //** return to the application outside the FlashVault. Write status info in
    //** SS_STATUS allowing the restore of the secure code execution once we get 
    //** back from the interrupt handling performed outside the FlashVault.
    //**
__flashvault_irq_handle:
    // We must save all registers on the stack else the secure code application
    // will fail when it resumes!
    sub    sp, 2*4            // Save room for RAR and RSR
    pushm  r0-r12,lr          // Push R0-R12 & LR on the stack
    sub    sp, -16*4          // Reset the SP to the appropriate position before saving RAR & RSR.
  
    // Put RSR and RAR of the interrupted secure application on the secure stack.
    mfsr   r0, AVR32_SS_RAR
    st.w   --sp, r0
    mfsr   r0, AVR32_SS_RSR
    st.w   --sp, r0

    // Update SS_STATUS with a value indicating that the secure code was interrupted.
    mov    r0, SEC_EXE_STATUS_INTERRUPTED
    mtsr   AVR32_SS_STATUS, r0

    // Restore the SS_RAR & SS_RSR from the original SSCALL call (these were saved
    // in the SSCALL handler in the ss_rar_save & ss_rsr_save variables).
    // Note that SS_RAR will then be set to the application outside the FlashVault
    // on the SSCALL instruction that was issued to reach the FlashVault API.
    mov   r0, ss_rar_save
    ld.w  r1, r0[0]
    mtsr  AVR32_SS_RAR, r1
    mov   r0, ss_rsr_save
    ld.w  r1, r0[0]
    mtsr  AVR32_SS_RSR, r1

    // Return to the application outside the FlashVault to handle the IRQ.
    // NOTE: In the world outside the FlashVault, once the IRQ handling is done,
    // rete will be executed which will restore execution on the SSCALL instruction
    // which will switch execution to the FlashVault in the SSCALL handler __flashvault_sscall_handle().
    retss


    .section  .data, "aw", @progbits

    .global ss_rar_save
    .type ss_rar_save, @object
    .org 0x0
ss_rar_save: .word

    .global ss_rsr_save
    .type ss_rsr_save, @object
    .org 0x4
ss_rsr_save: .word

#endif
