	.text
	.globl setjmp
setjmp:
	stm	r12, r0, r1, r2, r3, r4, r5, r6, r7, sp, lr
	retal	0

	.globl longjmp
longjmp:	
	ldm	r12, r0, r1, r2, r3, r4, r5, r6, r7, sp, lr
	/* Put the return value into the integer result register.
	   But if it is zero then return 1 instead.  */	
	cp	r11, 0
	reteq	1
	retal	r11


	

	
	
