	.align	2
	.global strncpy

strncpy :	
#ifdef __AVR32_UC__	
	mov	r8, 0
0:	
	cp.w	r10, r8
	reteq	r12
	ld.ub	r9, r11[r8]
	st.b	r12[r8], r9
	sub	r8, -1
	cp.w	r9, 0
	brne	0b

1:	
	cp.w	r10, r8
	reteq	r12
	st.b	r12[r8], r9
	sub	r8, -1
	rjmp	1b
#else
	mov	r8, r12
0:	
	sub	r10, 1
	ld.ub	r9, r11++
	retmi	r12
	st.b	r8++, r9
	cp.w	r9, 0
	brne	0b

1:	
	sub	r10, 1
	retmi	r12
	st.b	r8++, r9
	rjmp	1b
	
	
#endif	
