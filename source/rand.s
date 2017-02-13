.section .text
.globl	 rand

// The function that returns a random number based on the system state
rand:
	push {r4, lr}             
		  
	ldr     r0, =0x20003004             @ load address of low 32 bits of system timer register (CLO)
	ldr     r0, [r0]                    @ read CLO

	mov 	r1, #5
	mov	r2, #4
	mov 	r3, #10
	mov 	r4, r0	  	  // r4 = r0 = x = t

	eor r4, r4, lsl #11       // t << 11
	eor r4, r4, lsr #8        // t >> 8

	mov r0, r1                // x = y
	mov r1, r2                // y = z
	mov r2, r3                // z = w

	eor r3, r3, lsr #19       // w ^= w >> 19
	eor r3, r4                // w ^= t
	mov r0, r3
    
	pop {r4, pc}              // returns w = r3, x = r0, y = r1, z = r2

