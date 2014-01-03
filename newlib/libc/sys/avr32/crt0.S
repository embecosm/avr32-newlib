
	.section	.reset,"ax"
	
	.global _start
	.type	_start,@function
_start:
	/* Jump to wherever the linker thinks we are... */
	lddpc	pc, .Ltext_vaddr

	.align	2
.Ltext_vaddr:
	.word	_stext

	.text
	.global	_stext
_stext:
	/* Zero marks the end of the outermost frame.  */
	mov	r7, 0

	/*  Set up the stack pointer to a fixed value */
	lda.w	r10, _estack

	/*  If _stack is -1 don't set sp, the stack is then probably
	    set by some other means i.e. by a bootloader. */
	cp	r10, -1
	movne	sp, r10

	/* Copy the data segment into RAM if necessary. If data_lma
	   is equal to data then VMA==LMA and no copying is necessary.
	   The linker script must make sure that the data segment is at
	   least dword-aligned.  */
	lda.w	r11, _data_lma
	lda.w	r12, _data
	cp.w	r11, r12
	breq	1f
	lda.w	r10, _edata
2:	ld.d	r8, r11++
	st.d	r12++, r8
	cp.w	r12, r10
	brlt	2b
	
	/* Zero the memory in the .bss section.  */
1:	lda.w	r10, _end
	lda.w	r12, _edata

	mov	r8, 0
	mov	r9, 0
2:	st.d	r12++, r8
	cp.w	r12, r10
	brlt	2b

	/* User dependent initialization */
	call	_init_startup

	/* Register _fini function with atexit 
	   The _fini function is responsible for calling destructiors */
	lda.w	r12, _fini
	call	atexit

	/* Call _init in order to initialize constructors etc */
	call	_init
		
	/*Initialize argv, use stack for keeping arguments. 
          _init_argv() returns argc in r12 and argv in r11
	 and the total size used for the arguments in r10.*/
	mov	r12, sp	
	/* Signal that we are storing the arguments in a stackwise
	   top down approach. */	
	mov	r11, 0	
	call	_init_argv
	/* If initialization if argv is not handled then _init_argv
           returns -1 so set argc to 0 and make sure no space is 
	   allocated on the stack. */
	cp.w	r12, -1
	moveq	r12, 0
	moveq	r10, 0
	sub	sp, r10

	/* Call main and call exit when it returns */
	call	main
	call	exit

	.weak	_data_lma
