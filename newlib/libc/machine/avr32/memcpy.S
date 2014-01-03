/*
 * Copyright (C) 2004,2005,2006,2007,2008,2009 Atmel Corporation
 */

/* Don't use r12 as dst since we must return it unmodified */

	.text
	.global	memcpy
	.type	memcpy, @function
#if  defined(__AVR32_HAS_UNALIGNED_WORD__)
memcpy:	
	/* Check if src and dst are aligned
	   if not do a word based copying. */
	or	r9, r12, r11
	andl	r9, 3, COH
	brne	.Lunaligned_copy	

	pushm	r12, lr
	sub	r10, 8
	brmi	.Lword_copy

0:	
	ld.d	r8, r11++
	sub	r10, 8	
	st.d	r12++, r8
	brpl	0b
	
.Lword_copy:	
	sub	r10, -4
	brmi	.Lbyte_copy

0:	
	ld.w	r8, r11++
	sub	r10, 4	
	st.w	r12++, r8
	brpl	0b

.Lbyte_copy:
	sub	r10, -4	
	breq	2f
1:	
	ld.ub	r8, r11++
	sub	r10, 1
	st.b	r12++, r8
	brne	1b
2:	
	popm	r12, pc

.Lunaligned_copy:
	mov	r9, r12
	sub	r10, 4	

	brmi	.Lbyte_copy2

0:	
	ld.w	r8, r11++
	sub	r10, 4	
	st.w	r12++, r8
	brpl	0b

.Lbyte_copy2:
	sub	r10, -4	
	reteq	r9
1:	
	ld.ub	r8, r11++
	sub	r10, 1
	st.b	r12++, r8
	brne	1b

	ret	r9

					
#else	
	
#define dst r9
#define src r11
#define len r10
	
#if  defined(__AVR32_UC__)	
memcpy:
	/* If we have less than 8 bytes, don't do anything fancy 
	   just an unrolled byte copy */
	cp.w	r10, 8
	brlt	.Lless_than_8
	/* Check if src and dst are aligned. */
	or	r9, r12, r11
	andl	r9, 3, COH
	brne	.Lunaligned_copy	

	/* Check if larger than 31 */
	cp.w	r10, 32
	brge	.Lmore_than_31:

	/* Less than 32. */
	asr	r8, r10, 2
	rsub	r9, r8, 8
	add	pc, pc, r9 << 2
	.irp	offset,0,1,2,3,4,5,6
	ld.w	r9, r11[(6-\offset)*4]
	st.w	r12[(6-\offset)*4], r9
	.endr
	
	add	r11, r11, r8 << 2 
	add	r8, r12, r8 << 2 
	andl	r10, 0x3 
	rsub	r10, r10, 4
	add	pc, pc, r10 << 2
	.irp	offset,0,1,2
	ld.ub	r9, r11[2-\offset]
	st.b	r8[2-\offset], r9
	.endr
	
	retal	r12

.Lless_than_8:	
	rsub	r10, r10, 9
	add	pc, pc, r10 << 2
	.irp	offset,0,1,2,3,4,5,6,7
	ld.ub	r9, r11[7-\offset]
	st.b	r12[7-\offset], r9
	.endr
	
	retal	r12

.Lmore_than_31:
	stm	--sp, r6-r7, lr
	mov	r9, r12

.Laligned_copy:
	sub	r10, 32

1:	/* Copy 32 bytes at a time */
	ld.d	r6, r11++
	st.d	r9++, r6
	ld.d	r6, r11++
	st.d	r9++, r6
	ld.d	r6, r11++
	st.d	r9++, r6
	ld.d	r6, r11++
	st.d	r9++, r6
	sub	r10, 32
	brge	1b
	
.Lless_than_32:
	/* Copy 16 more bytes if possible */
	sub	r10, -16
	brlt	.Lless_than_16
	ld.d	r6, r11++
	st.d	r9++, r6
	ld.d	r6, r11++
	st.d	r9++, r6
	sub	r10, 16

.Lless_than_16:

	/* Do the remaining as byte copies */
	neg	r10
	add	pc, pc, r10 << 3
	nop
	nop
	.irp	offset,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14
	ld.ub	r6, r11[14-\offset],e
	st.b	r9[14-\offset], r6,e
	.endr
	
	ldm	sp++, r6-r7, pc

.Lunaligned_copy:	
	/* src and dst are unaligned. */
0:	
	sub	r10, 1
	ld.ub	r9, r11[r10]
	st.b	r12[r10], r9
	brne	0b
	
	retal	r12	
	.size	memcpy, . - memcpy

#else
memcpy:
	pref	src[0]
	mov	dst, r12

	/* If we have less than 32 bytes, don't do anything fancy */
	cp.w	len, 32
	brge	.Lmore_than_31

	sub	len, 1
	retlt	r12
1:	ld.ub	r8, src++
	st.b	r12, r8
	sub	len, 1
	brge	1b
	retal	r12

.Lmore_than_31:
	pushm	r0-r7, lr

	/* Check alignment */
	mov	r8, src
	andl	r8, 31, COH
	brne	.Lunaligned_src
	mov	r8, dst
	andl	r8, 3, COH
	brne	.Lunaligned_dst

.Laligned_copy:
	sub	len, 32
	brlt	.Lless_than_32

1:	/* Copy 32 bytes at a time */
	pref	src[32]
	ldm	src, r0-r7
	sub	src, -32
	stm	dst, r0-r7
	sub	dst, -32
	sub	len, 32
	brge	1b
	
.Lless_than_32:
	/* Copy 16 more bytes if possible */
	sub	len, -16
	brlt	.Lless_than_16
	ldm	src, r0-r3
	sub	src, -16
	sub	len, 16
	stm	dst, r0-r3
	sub	dst, -16

.Lless_than_16:
	/* Do the remaining as byte copies */
	neg	len
	add	pc, pc, len << 2
	.rept	15
	ld.ub	r0, src++
	st.b	dst++, r0
	.endr

	popm	r0-r7, pc

.Lunaligned_src:
	/* Make src cacheline-aligned. r8 = (src & 31) */
	rsub	r8, r8, 32
	sub	len, r8
1:	ld.ub	r0, src++
	st.b	dst++, r0
	sub	r8, 1
	brne	1b

	/* If dst is word-aligned, we're ready to go */
	pref	src[0]
	mov	r8, 3
	tst	dst, r8
	breq	.Laligned_copy

.Lunaligned_dst:
	/* src is aligned, but dst is not. Expect bad performance */
0:	
	ld.ub	r0, src++
	st.b	dst++, r0
	sub	len, 1
	brne	0b
	
	popm	r0-r7, pc
	.size	memcpy, . - memcpy


#endif
#endif
