.section .text

.globl	Init_SNES
.globl 	Read_SNES
.globl	Wait

//
//  ********* SNES CONTOLLER BUTTON LAYOUT *********
//
//  Bit number  |  Button
//      0       |     B
//      1       |     Y
//      2       |     Select
//      3       |     Start
//      4       |     UP
//      5       |     DOWN
//      6       |     LEFT
//      7       |     RIGHT
//      8       |     A
//      9       |     X
//     10       |     Left Bumper
//     11       |     Right Bumper
//
//
// Note bit=1 means button is NOT pressed bit=0 means button is pressed

Init_GPIO:                              @ sets function of GPIO pin - r0 = GPIO pin#, r1 = pin function

    push    {r4-r6, lr}                 @ save registers on stack

    mov     r4, r0                      @ save pin# for later
    mov     r5, r1                      @ save pin function for later

    ldr     r6, =0x20200000             @ set base address for GPFSEL in r6

    mov     r1, #10                     @ set divisor to 10
    bl      sdiv                        @ compute pin# / 10

    add     r6, r0, lsl #2              @ compute register offset = base address + 4*(pin# / 10)
    add     r1, r1, lsl #1              @ compute pin offset = (pin % 10) * 3

    ldr     r0, [r6]                    @ load GPFSEL{n}

    mov     r2, #7                      @ load clear mask 0b0111
    lsl     r2, r1                      @ shift clear mask to mask pin bits
    bic     r0, r2                      @ clear current pin function

    lsl     r5, r1                      @ shift function mask to mask pin bits
    orr     r0, r5                      @ set pin function to function mask

    str     r0, [r6]                    @ write back GPFSEL{n}

    pop     {r4-r6, pc}                 @ return to calling function


Write_GPIO:                             @ sets a GPIO pin high - r0 = pin number, r1 = bit to write (either 0 or 1)

    cmp     r1, #1						@ check value to write

    ldreq   r2, =0x2020001C             @ load address of GPSET0 register if bit to write is 1
    ldrne   r2, =0x20200028             @ load address of GPCLR0 register if bit to write is 0

    mov     r3, #1                      @ load 1 to write to GPIO register
    lsl     r3, r0                      @ shift bit to set up to pin
    str     r3, [r2]                    @ set bit in GPIO register

    bx      lr                          @ return to calling code


Read_GPIO:                              @ reads from a GPIO pin - r0 = pin number | returns pin value (either 0 or 1)

    ldr     r1, =0x20200034             @ load address of GPLEV0 in r1
    ldr     r1, [r1]                    @ load value of GPLEV0 in r1

    mov     r3, #1                      @ set mask bit
    lsl     r3, r0                      @ shift mask bit up to bit corresponding to given pin
    and     r1, r3                      @ mask bit with value of GPLEV0

    teq     r1, #0                      @ test pin value

    moveq   r0, #0                      @ if pin value is low set return value to 0
    movne   r0, #1                      @ if pin value is high set return value to 1

    bx      lr                          @ return to calling code


Wait:                                   @ returns after the given number of microseconds - r0 = number of microseconds to wait for

    ldr     r1, =0x20003004             @ load address of low 32 bits of system timer register (CLO)
    ldr     r2, [r1]                    @ read CLO

    add     r2, r0                      @ add desired wait time to CLO

waitLoop:
    ldr     r3, [r1]                    @ read CLO

    cmp     r2, r3                      @ check if elapsed time is > than desired wait time
    bhi     waitLoop                    @ continue waiting if insufficient time has passed

    bx      lr                          @ return to calling code


Write_Latch:                            @ writes to GPIO pin 9 for SNES controller latch - r0 = bit to write (either 0 or 1)

    push    {lr}                        @ save link register on the stack

    mov     r1, r0                      @ set bit to write in r1
    mov     r0, #9                      @ set pin number to GPIO 9 (SNES controller latch)
    bl      Write_GPIO                  @ write bit to SNES latch

    pop     {pc}                        @ return to calling code


Write_Clock:                            @ writes to GPIO pin 11 for SNES controller clock - r0 = bit to write (either 0 or 1)

    push    {lr}                        @ save link register on the stack

    mov     r1, r0                      @ set bit to write in r1
    mov     r0, #11                     @ set pin number to GPIO 11 (SNES controller clock)
    bl      Write_GPIO                  @ write bit to SNES clock

    pop     {pc}                        @ return to calling code


Read_SNES:                              @ reads current state of SNES controller - returns buttons pressed as bit flags in r0 (bits 0-11 1 means button is pressed)
                                        @ refer to button layout table at top of page
    push    {r4-r5, lr}                 @ prevent register clobbering, push old values on stack

    mov     r0, #1                      @ set bit to write in r0
    bl      Write_Clock                 @ pull clock GPIO pin high

    mov     r0, #1                      @ set bit to write in r0
    bl      Write_Latch                 @ pull latch GPIO pin high

    mov     r0, #12                     @ set time (in microseconds) to wait
    bl      Wait                        @ wait for 12 microseconds

    mov     r0, #0                      @ set bit to write in r0
    bl      Write_Latch                 @ pull latch GPIO pin low

    mov     r4, #0                      @ clear r4, used as counter register
    mov     r5, #0                      @ clear r5, used to store bit flags

read_SNES_loop:
    mov     r0, #6                      @ set time (in microseconds) to wait
    bl      Wait                        @ wait for 6 microseconds

    mov     r0, #0                      @ set bit to write in r0
    bl      Write_Clock                 @ pull clock GPIO pin low

    mov     r0, #6                      @ set time (in microseconds) to wait
    bl      Wait                        @ wait for 6 microseconds

    mov     r0, #10                     @ set pin number to read (pin #10)
    bl      Read_GPIO                   @ read bit from SNES data pin
    
    eor		r0, #1						@ flip result so that bit is 1 when button is pressed
    orr		r5, r0, lsl r4				@ set appropriate bit flag

    mov     r0, #1                      @ set bit to write in r0
    bl      Write_Clock                 @ pull clock GPIO pin high

    add     r4, #1                      @ increment counter
    cmp     r4, #16                     @ check if we have read all 16 bits of SNES data

    blt     read_SNES_loop              @ if there is remaining SNES data to read continue reading data

    mov     r0, r5                      @ set return value to accumulated bit flags

    pop     {r4-r5, pc}                 @ restore old register values and return to calling code


Init_SNES:

    push    {lr}                        @ save lr to stack so we can return to calling function later

    @@@@@@@@ ------- INIT LATCH GPIO ------- @@@@@@@@
    mov     r0, #9
    mov     r1, #1
    bl      Init_GPIO

    @@@@@@@@ ------- INIT DAT GPIO ------- @@@@@@@@
    mov     r0, #10
    mov     r1, #0
    bl      Init_GPIO

    @@@@@@@@ ------- INIT CLOCK GPIO ------- @@@@@@@@
    mov     r0, #11
    mov     r1, #1
    bl      Init_GPIO

    pop     {pc}                        @ return to calling code
