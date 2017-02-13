.section .text
.globl	 InitFrameBuffer
.globl 	 DrawPixel

InitFrameBuffer:						@ initializes framebuffer
	
	ldr		r1, =0x2000B880				@ load address of mailbox			
	ldr		r2, =FrameBufferInit		@ load address of framebuffer initialization data
	
mailFullLoop:
	ldr		r0, [r1, #0x18]				@ load mailbox status register
	
	tst		r0, #0x80000000				@ check if mailbox is full (bit 31 set)
	bne		mailFullLoop				@ wait until mailbox is not full
	
	add		r0, r2, #0x40000000			@ add 0x40000000 to address of framebuffer init struct, store in r0
	orr		r0, #0b0001					@ set channel number
	
	str		r0, [r1, #0x20]
	
mailEmptyLoop:
	ldr		r0,	[r1, #0x18]				@ load mailbox status register
	
	tst		r0, #0x40000000				@ check if mailbox is empty (bit 30 set)
	bne		mailEmptyLoop				@ wait until mailbox is empty
	
	ldr		r0, [r1, #0x00]				@ read response from mailbox read register

	and		r3, r0, #0xF				@ mask out channel information

	teq		r3, #0b0001					@ check if this message is from channel 1

	bne		mailEmptyLoop				@ read another message if this message is not from channel 1

	bic		r3, r0, #0xF				@ isolate the high 28 bits of the message

	teq		r3,	#0						@ test if the high 28 bits of the message are 0 (i.e. success)
	
	movne	r0,	#0						@ return 0 if high 28 bits of message are not 0
	bxne	lr							@ return to calling code

pointerLoop:
	ldr		r0,	[r2, #0x20]				@ load the value of the pointer from the framebuffer init struct

	teq		r0,	#0						@ check if pointer from framebuffer init struct is 0
	beq		pointerLoop					@ loop until pointer is not 0
	
	ldr		r3, =FrameBufferPointer		@ load address of FrameBufferPointer storage region
	str		r0, [r3]					@ store FrameBuffer address to FrameBufferPointer 

	bx		lr							@ return to calling code
	
	
DrawPixel:								@ draws pixel - r0=x r1=y r2=16-bit color

	add		r3,	r0, r1, lsl #10			@ offset = (y * 1024) + x
	lsl		r3, #1						@ offset *= 2 (for 16 bits per pixel = 2 bytes per pixel)

	ldr		r0, =FrameBufferPointer		@ load address of frame buffer pointer
	ldr		r0, [r0]					@ load address of frame buffer
	strh	r2, [r0, r3]				@ store color at desired pixel in frame buffer

	bx		lr							@ return to calling code
	
.section .data
.globl FrameBufferPointer

.align 4
FrameBufferInit:
	.int	1024		// X Resolution (width)
	.int	768			// Y Resolution (height)
	.int	1024		// Virtual Width
	.int	768			// Virtual Height
	.int	0			// Pitch (Set by GPU)
	.int	16			// Depth (bits per pixel)
	.int	0			// Virtual X Offset
	.int	0			// Virtual Y Offset
	.int	0			// Pointer to FrameBuffer (Set by GPU)
	.int	0			// Size of FrameBuffer (Set by GPU)
	
.align 4
FrameBufferPointer:
	.int	0
