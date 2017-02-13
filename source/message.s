.section .text
.globl	 strlen
.globl	 Print_Message

strlen:                                 @ computes and returns length of given string - r0 = address of string | returns length of string in r0

    add     r2, r0, #1                  @ Store address of string for comparsion later (add is to exclude null terminator)

strlen_next_char:
    ldrb    r1, [r0], #1                @ Load current byte of string and increment address to next char
    cmp     r1, #0                      @ Check if null terminator has been reached

    bne     strlen_next_char            @ Keep scanning characters until null terminator has been reached

    sub     r0, r2                      @ compute string length by subtracting terminator address from base address

    bx      lr                          @ return to calling function


Print_Message:                          @ prints string to UART - r0 = address of string to be printed

    push    {r4, lr}                    @ save link register and r4

    mov     r4, r0                      @ save input string address for later use
    bl      strlen                      @ compute length of string

    mov     r1, r0                      @ r0 contains length of string, needs to be in r1
    mov     r0, r4                      @ r4 contains address of string to write to UART, needs to be in r0
    bl      WriteStringUART             @ Write string to UART

    pop     {r4, pc}                    @ return to calling function and restore r4
