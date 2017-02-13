.section .text

.globl	 Wait_Async
.globl	 Enable_Timer_IRQ
.globl	 Install_Interrupt_Table
.globl	 Enable_Interrupts
.globl	 Disable_Timer_IRQ

Install_Interrupt_Table:                @ loads and installs the interrupt vector table at memory address 0x0

    ldr     r0, =ISRTable               @ load ISR table address to copy into r0
    mov     r1, #0x0                    @ load address 0x0 into r1

    ldmia   r0!, {r2-r9}                @ load ldr branch instructions
    stmia   r1!, {r2-r9}                @ fill IVT with branch instructions
    ldmia   r0!, {r2-r9}                @ load handler addresses
    stmia   r1!, {r2-r9}                @ store handler addresses
    
    mov		r0, #0xD2					@ 11010010 IRQ mode I & F bits high
    msr		cpsr_c, r0					@ disable interrupts
    mov		sp, #0x8000					@ set IRQ stack pointer
    
    mov		r0, #0xD3					@ supervisor mode
    msr		cpsr_c, r0					@ switch to supervisor mode
    mov		sp, #0x8000000				@ set supervisor mode stack pointer

    bx		lr                      	@ return to calling code


Enable_Interrupts:                      @ Enabales IRQ interrupts globally

    mrs     r0, cpsr                    @ store cpsr in r0
    bic     r0, #0x80                   @ clear bit 7 (I flag) to enable interrupts in cpsr
    msr     cpsr_c, r0                  @ set new control mask in cpsr

    bx	    lr                      	@ return to calling code


Enable_Timer_IRQ:						@ Enables system timer compare IRQ lines

    ldr     r0, =0x2000B210             @ load address of Enable IRQs 1 into r0
    mov     r1, #0x2                    @ load 0b10 into r1
    str     r1, [r0]                    @ set bit# 1 of Enable IRQs 1 to enable interrupts for system timer compare register 1

    bx		lr                     		@ return to calling code
    

Disable_Timer_IRQ:						@ Disables system timer compare IRQ lines

	ldr		r0, =0x2000B21C				@ load address of Disable IRQs 1 into r0
	mov		r1, #0x2					@ load 0b10 into r1
	str		r1, [r0]					@ set bit# 1 of Disable IRQs 1 to disable interrupts for system timer compare register 1
	
	ldr     r0, =timer_irq_handler      @ load address of handler storage location
	ldr		r1, =empty					@ load address of blank handler
    str     r1, [r0]                    @ store address of empty for blank handling

    ldr     r0, =0x20003004             @ load address of low 32 bits of system timer register (CLO)
    ldr     r0, [r0]                    @ read CLO

    sub     r0, #1                      @ compute time in the past (that won't trigger interrupt on re-enable)

    ldr     r1, =0x20003010             @ get address of system timer compare 1 in register r0
    str     r0, [r1]                    @ set timer compare 1 to value in past 
	
	bx		lr							@ return to calling code


Service_IRQ:                            @ services system timer interrupts since that is the only interrupt we have enabled

    push    {r0-r3, lr}                 @ save registers to stack

    ldr     r0, =0x20003000             @ load system timer control/status register address
    mov     r1, #0x2                    @ set status bit# 1 to indicate timer interrupt has been serviced
    str     r1, [r0]                    @ write back system timer control/status register

	ldr     r0, =timer_irq_handler      @ load address of handler storage location
    ldr     r0, [r0]                    @ load address of handler
    blx     r0                          @ call handler to notify timer interrupt has occured

    pop     {r0-r3, lr}                 @ restore registers
    subs	pc, lr, #4					@ exit IRQ handler


Wait_Async:                             @ calls handler via interrupt after the desired amount of time has passed | r0 = time to wait in microseconds r1 = address of handler

    ldr     r2, =timer_irq_handler      @ load address of handler storage location
    str     r1, [r2]                    @ store address of handler for interrupt handling later

    ldr     r1, =0x20003004             @ load address of low 32 bits of system timer register (CLO)
    ldr     r1, [r1]                    @ read CLO

    add     r1, r0                      @ add desired wait time to CLO

    ldr     r0, =0x20003010             @ get address of system timer timer compare 1 in register r0
    str     r1, [r0]                    @ set timer compare 1 to fire interrupt when CLO == CLO+time_to_wait

    bx      lr                          @ return to calling code
    
hang:                                   
    b   hang

empty:
    bx  lr

.section .data

ISRTable:
ldr     pc, reset_handler
ldr     pc, undefined_handler
ldr     pc, swi_handler
ldr     pc, prefetch_handler
ldr     pc, data_handler
ldr     pc, unused_handler
ldr     pc, irq_handler
ldr     pc, fiq_handler

reset_handler:      .word hang
undefined_handler:  .word hang
swi_handler:        .word hang
prefetch_handler:   .word hang
data_handler:       .word hang
unused_handler:     .word hang
irq_handler:        .word Service_IRQ
fiq_handler:        .word hang

timer_irq_handler:  .word empty
