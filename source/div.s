.section .text
.globl	 sdiv

sdiv:                                   @ computes the signed division of r0/r1 and returns the result in r0 - r0 = dividend, r1 = divisor | r0 = quotient
@@@@@@@@ ------- HANDLE SIGN ------- @@@@@@@@@

    push    {r4, lr}                    @ save r4 and link register onto stack

    eor     r4, r0, r1                  @ compute dividend xor divisor to determine if sign differs or not
    lsr     r4, #31                     @ shift sign bit down to prevent uneeded ldr later

    ldr     r2, =0x80000000             @ store sign mask constant

    tst     r0, r2                      @ check if dividend is negative
    negne   r0, r0                      @ if dividend is <0 take absolute value

    tst     r1, r2                      @ check if divisor is negative
    negne   r1, r1                      @ if divisor is <0 take absolute value

@@@@@@@@ ------- BEGIN UNSIGNED DIVISION ------- @@@@@@@@@

    mov     r2, r0                      @ move dividend into r2 (so r0 can hold result)
    mov     r0, #0                      @ clear result reigster

    mov     r3, #1                      @ stores ceil power of 2

sdiv_pow2_loop:                         @ while(divisor < dividend)
    lsl     r1, #1                      @ left shift logical divisor (multiply by 2)
    lsl     r3, #1                      @ calculate ceil power of 2

    cmp     r1, r2                      @ compare divisor and dividend
    blo     sdiv_pow2_loop              @ repeat until first greater power of 2 is found

sdiv_shift_sub_loop:
    cmp     r2, r1                      @ compare dividend and divisor
    blo     sdiv_shift_right            @ jump to right shift if(dividend >= divisor)

    sub     r2, r1                      @ remainder -= divisor (eventually computes remainder)
    add     r0, r3                      @ quotient += r3 (eventually computes result)

sdiv_shift_right:
    lsr     r1, #1                      @ right shift logical divisor (divide by 2)
    lsr     r3, #1                      @ right shift logical mask register r3

    cmp     r3, #0                      @ check if r3 is 0
    bne     sdiv_shift_sub_loop         @ continue shifting until r3 is 0

    mov     r1, r2                      @ store remainder in r1

    cmp     r4, #1                      @ check if result will be negative
    negeq   r0, r0                      @ negate quotient if result should be negative
    negeq   r1, r1                      @ negate remainder if result should be negative

    pop     {r4, pc}                    @ return to calling code
