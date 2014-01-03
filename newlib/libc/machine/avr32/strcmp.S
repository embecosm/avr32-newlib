	.align	2
	.global strcmp

strcmp:	
#if !defined(__AVR32_HAS_UNALIGNED_WORD__)
#ifdef __AVR32_UC__
	/* Check if both strings are aligned. */
	or	r10, r12, r11
	andl	r10, 3, COH
	brne	.Lbyte_strcmp	
0:		
	ld.w	r10, r12[0]
	ld.w	r9, r11[0]
	tnbz	r10
	breq	1f
	cp.w	r10, r9
	brne	1f
	ld.w	r10, r12[4]
	ld.w	r9, r11[4]
	tnbz	r10
	breq	1f
	cp.w	r10, r9
	brne	1f
	ld.w	r10, r12[8]
	ld.w	r9, r11[8]
	tnbz	r10
	breq	1f
	cp.w	r10, r9
	brne	1f
	ld.w	r10, r12[12]
	ld.w	r9, r11[12]
	tnbz	r10
	breq	1f
	sub	r12, -16
	sub	r11, -16
	cp.w	r10, r9
	breq	0b
1:
	bfextu	r12, r10, 24, 8
	bfextu	r11, r9, 24, 8
	reteq	r12
	sub	r12, r11
	retne	r12
		
	bfextu	r12, r10, 16, 8
	bfextu	r11, r9, 16, 8
	reteq	r12
	sub	r12, r11
	retne	r12

	bfextu	r12, r10, 8, 8
	bfextu	r11, r9, 8, 8
	reteq	r12
	sub	r12, r11
	retne	r12

	castu.b	r10
	castu.b	r9
	sub	r10, r9
	ret	r10	

.Lbyte_strcmp:	
0:	
	ld.ub	r10, r11[0]
	ld.ub	r9, r12[0]
	cp.w	r10, 0
	reteq	r9
	sub	r9, r10
	retne	r9
	ld.ub	r10, r11[1]
	ld.ub	r9, r12[1]
	cp.w	r10, 0
	reteq	r9
	sub	r9, r10
	retne	r9
	ld.ub	r10, r11[2]
	ld.ub	r9, r12[2]
	cp.w	r10, 0
	reteq	r9
	sub	r9, r10
	retne	r9
	ld.ub	r10, r11[3]
	ld.ub	r9, r12[3]
	cp.w	r10, 0
	reteq	r9
	sub	r9, r10
	retne	r9
	sub	r11, -4
	sub	r12, -4
	rjmp	0b
#else
0:	
	ld.ub	r10, r11++
	ld.ub	r9, r12++
	cp.w	r10, 0
	reteq	r9
	sub	r9, r10
	breq	0b
	ret	r9
#endif
#else
0:	
	ld.w	r10, r12++
	ld.w	r9, r11++
	tnbz	r10
	breq	1f
	cp.w	r10, r9
	breq	0b
	
1:
	bfextu	r12, r10, 24, 8
	bfextu	r11, r9, 24, 8
	reteq	r12
	sub	r12, r11
	retne	r12
		
	bfextu	r12, r10, 16, 8
	bfextu	r11, r9, 16, 8
	reteq	r12
	sub	r12, r11
	retne	r12

	bfextu	r12, r10, 8, 8
	bfextu	r11, r9, 8, 8
	reteq	r12
	sub	r12, r11
	retne	r12

	castu.b	r10
	castu.b	r9
	sub	r10, r9
	ret	r10	
#endif	
