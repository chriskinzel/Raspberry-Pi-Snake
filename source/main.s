.section    .init
.globl     _start

_start:
    b       main

.section .text


//---------------------------------------- Draws an image, loaded in r0, at the dimensions (x, y) in the form (r1, r2) ----------------------------------------------
Draw_Image:                             @ renders an image to the framebuffer - r0 = image buffer r1 = x r2 = y

    push    {r4-r12, lr}                @ save registers to stack

    ldr     r3, [r0], #4                @ load image width into register r3
    ldr     r4, [r0], #4                @ load image height into register r4

    ldr     r5, =FrameBufferPointer     @ load address of frame buffer pointer
    ldr     r5, [r5]                    @ load address of frame buffer

    add		r6, r1, r2, lsl #10			@ calculate offset from x and y coordinates
	add		r5, r6, lsl #1				@ offset into framebuffer

    mov     r1, r3                      @ keeps track of number of pixels written horizontally

pixelBlockCopyLoop:
    subs    r1, #16                     @ check if we can copy 16 pixels
    blt     pixelSingleCopyLoop         @ handle remaining number of pixels less than 16

    ldmia   r0!, {r6-r12,r14}           @ read 16 pixels from image buffer
    stmia   r5!, {r6-r12,r14}           @ write 16 pixels to framebuffer

    beq     nextRow                     @ if there were exactly 16 remaining pixels copied move to the next row
    b       pixelBlockCopyLoop

pixelSingleCopyLoop:
    ldrh    r2, [r0], #2                @ load a single pixel from the image buffer into r2
    strh    r2, [r5], #2                @ write pixel to framebuffer

    sub     r1, #1                      @ decrement number of pixels remaining
    cmp     r1, #-16                    @ number of pixels remaining is relative to -16 in this loop
    bgt     pixelSingleCopyLoop         @ loop until all remaining pixels have been copied

nextRow:
    mov     r1, r3                      @ reset horizontal pixel tracker

    add     r5, #2048                   @ increment y (1024 * 2)
    sub     r5, r3, lsl #1              @ move framebuffer offset back to image x origin (width*2)

    subs    r4, #1                      @ decrement remaining rows
    bgt     pixelBlockCopyLoop          @ loop until all rows of the image have been copied

    pop     {r4-r12, pc}                @ restore registers and return to calling code






//------------------------------------  Draws a rectangle of color set in r0, with the top left corner location (x, y) in the form (r1, r2). ---------
//------------------------------------  R3 is the width and the height is speciified on the stack. ---------------------------------------------------
Draw_Rect:                              @ renders a solid color rect to the framebuffer - r0 = color r1 = x r2 = y r3 = width - height passed on stack

    push    {r4-r12, lr}                @ save registers to stack
	ldr		r4, [sp, #40]				@ load heigh from stack

    ldr     r5, =FrameBufferPointer     @ load address of frame buffer pointer
    ldr     r5, [r5]                    @ load address of frame buffer

    add		r6, r1, r2, lsl #10			@ calculate offset from x and y coordinates
	add		r5, r6, lsl #1				@ offset into framebuffer

    mov     r1, r3                      @ keeps track of number of pixels written horizontally

@@@@@@		copy color value	@@@@@@\
	orr		r0, r0, lsl #16
    mov		r6, r0
    mov		r7, r0
    mov		r8, r0
    mov		r9, r0
    mov		r10, r0
    mov		r11, r0
    mov		r12, r0
    mov		r14, r0

rectBlockCopyLoop:
    subs    r1, #16                     @ check if we can copy 16 pixels
    blt     rectSingleCopyLoop          @ handle remaining number of pixels less than 16

    stmia   r5!, {r6-r12,r14}           @ write 16 pixels to framebuffer

    beq     rectNextRow                 @ if there were exactly 16 remaining pixels copied move to the next row
    b       rectBlockCopyLoop

rectSingleCopyLoop:
    strh    r0, [r5], #2                @ write pixel to framebuffer

    sub     r1, #1                      @ decrement number of pixels remaining
    cmp     r1, #-16                    @ number of pixels remaining is relative to -16 in this loop
    bgt     rectSingleCopyLoop          @ loop until all remaining pixels have been copied

rectNextRow:
    mov     r1, r3                      @ reset horizontal pixel tracker

    add     r5, #2048                   @ increment y (1024 * 2)
    sub     r5, r3, lsl #1              @ move framebuffer offset back to image x origin (width*2)

    subs    r4, #1                      @ decrement remaining rows
    bgt     rectBlockCopyLoop           @ loop until all rows of the image have been copied

    pop     {r4-r12, pc}                @ restore registers and return to calling code







//------------------------------------- A subroutine used to update the game stats, such as score and lives. -------------------------------------
updateStats:
    push {r4, r5, lr}
    ldr r0, =score
    ldr r0, [r0]
    mov r1, #10
    bl sdiv     // find quotient and remainder of score

    mov r5, r0  // r4 = quotient
    mov r4, r1  // r1 = remainder

    mov r0, r5
    mov r1, #396
    bl printNumber

    mov r0, r4
    mov r1, #412
    bl printNumber

@@@@@@@@@@@@@-lives-@@@@@@@@@@@@@@@
    ldr r0, =lives
    ldr r0, [r0]
    mov r1, #10
    bl sdiv     // find quotient and remainder of score

    mov r5, r0  // r4 = quotient
    mov r4, r1  // r1 = remainder

    mov r0, r5
    mov r1, #720
    bl printNumber

    mov r0, r4
    mov r1, #736
    bl printNumber

    pop {r4, r5, pc}

printNumber:             //r0 = number, r1 = offset
    push {r4, r5, r6, lr}
    mov r4, r0
    mov r5, r1
    mov r6, #-1

printNumberLoop:
    add r6, #1
    cmp r6, r4
    bne printNumberLoop
    ldr r0, =numberSpriteArray
    ldr r0, [r0, r6, lsl #2]
    mov r1, r5
    mov r2, #740
    bl  Draw_Image
    b   returnScore

returnScore:
    pop {r4, r5, r6, pc}







//--------------------------------------------- Draw map functions. Includes wall, boundry, and floor drawing. ----------------------------------------
Draw_Map:
	push 	{r4-r6, lr}


// Initialize the boundry tiles for top loop
topBoundry:
	mov 	r4, #0 				// DO WE NEED TO PUSH ELEMENTS ONTO THE STACK??? I DONT THINK SO BUT JUST CHECKING
	mov 	r5, #0

// Drawing the top boundry
topBoundryLoop:
	cmp 	r4, #31 					// If we are all the way at the right, goto bottomBoundry
	bgt 	bottomBoundry

	ldr		r0, =borderImage
	mov		r1, r4, lsl #5
	mov		r2, r5, lsl #5
	bl		Draw_Image

	add 	r4, #1
	b 		topBoundryLoop			// Keep drawing across until we hit the right most element. Then goto bottomBoundry

  // Initialize the boundry tiles for bottom loop
bottomBoundry:
  	mov 	r4, #0
  	mov 	r5, #22

  // Drawing the bottom boundry
bottomBoundryLoop:
  	cmp 	r4, #31 					// If we are all the way at the right, goto bottomBoundry
  	bgt 	leftBoundry

    ldr		r0, =borderImage
  	mov		r1, r4, lsl #5
  	mov		r2, r5, lsl #5
  	bl		Draw_Image

  	add 	r4, #1
  	b 		bottomBoundryLoop			// Keep drawing across until we hit the right most element. Then goto bottomBoundry




// Initialize the boundry tiles for left loop
leftBoundry:
	mov 	r4, #0
	mov 	r5, #0

// Drawing the left boundry
leftBoundryLoop:
	cmp 	r5, #21 					// If we are all the way at the bottom, goto rightBoundry
	bgt 	rightBoundry

  ldr		r0, =borderImage
	mov		r1, r4, lsl #5
	mov		r2, r5, lsl #5
	bl		Draw_Image

	add 	r5, #1
	b 		leftBoundryLoop			// Keep drawing across until we hit the right most element. Then goto rightBoundry


// Initialize the boundry tiles for right loop
rightBoundry:
	mov 	r4, #31
	mov 	r5, #0

// Drawing the right boundry
rightBoundryLoop:
	cmp 	r5, #21 					// If we are all the way at the bottom, goto drawFloor
	bgt 	drawFloor

  ldr		r0, =borderImage
	mov		r1, r4, lsl #5
	mov		r2, r5, lsl #5
	bl		Draw_Image

	add 	r5, #1
	b 		rightBoundryLoop			// Keep drawing across until we hit the right most element. Then goto rightBoundry

//Drawing the floor tiles
drawFloor:
  mov   r4, #1
  mov   r5, #1

//Drawing all the floor tiles
drawFloorLoop:
  cmp   r5, #21                // If the y bounds are too far, go to drawWalls and finish floor drawing
  bgt   drawWalls

  ldr		r0, =floorImage        // Drawing a floor tile at (r4,r5)
	mov		r1, r4, lsl #5
	mov		r2, r5, lsl #5             // Converting the tile number to the coordinates

  bl		Draw_Image
  cmp   r4, #30                // If the x bounds are too big, reset x (to one) and add one to y
  movge r4, #1
  addge r5, #1
  addlt r4, #1                // Increment x
  b     drawFloorLoop




// Draw the walls
drawWalls:
    	ldr 	r4, =levelOneWalls

// Looping the wall draw-er
drawWallsLoop:
	ldr 	r1, [r4], #4	// Load the element (x), then move "cursor" to next element
	cmp 	r1, #-1 		// Checks for end of the array
	beq 	endDrawMap
	cmp		r1, #-2			// Checks for cleared wall cell from drill value pack
	beq		drawWallsLoop	// Skip drawing this wall cell if cleared
	lsl		r1, #5			// Calculates where we draw x

	ldr 	r2, [r4], #4 	// Load the element (y), then move "cursor" to next element
	cmp 	r2, #-1 		// Checks for end of the array
	beq 	endDrawMap
	cmp		r2, #-2			// Checks for cleared wall cell from drill value pack
	beq		drawWallsLoop	// Skip drawing this wall cell if cleared
	lsl		r2, #5			// Calculates where we draw y

	ldr 	r0, =wallImage  // Draws the Wall wall at (x,y)
	bl 		Draw_Image
	b 		drawWallsLoop 	// Loops

// Resetting the stack
endDrawMap:
	pop		{r4-r6, pc}








//---------------------------------------------- Subroutine used for drawing the apples at random places, and saving location. Uses RNG function provided as a global ------------------------------------------------
Spawn_Apple:
	push 	{r4-r6, lr}

// The loop for the apple coordinate RNG
appleDrawLoop:
	bl		rand			// generates a random number based on system state for x
	lsr		r0, #1			// makes sure integer is unsigned ( > 0)
	mov 	r1, #29 		// The range for the x to be bounded by
	bl 		sdiv
	add 	r1, #1			// Increment the x by one to stay within the bounds
	mov 	r4, r1 			// Storing what the temp x value will be

	bl		rand			// generates a random number based on system state for y
	lsr		r0, #1			// makes sure integer is unsigned ( > 0)
	mov 	r1, #21	 		// The range for the y to be bounded by
	bl 		sdiv
	add 	r1, #1			// Increment the y by one to stay within the bounds
	mov 	r5, r1 			// Storing what the temp y value will be

appleWallCompare:
	ldr 	r6, =levelOneWalls

// 	The loop to compare all elements in the wall to the RNG coordinate
appleWallCompareLoop:
	ldr 	r0, [r6]		// Load the x
	cmp 	r0, #-1			// Check for the end of the array
	beq 	appleSnakeCompare
	cmp 	r0, r4			// Check if they "conflict"
	addne 	r6, #8			// Go to the next x if not equal
	bne 	appleWallCompareLoop

	add 	r6, #4			// If they are equal, then go to the related y
	ldr 	r0, [r6]		// load the y
	cmp 	r0, r5			// Check if the two y's are the same
	addne 	r6, #4			// If not equal, go to the next x and return to loop until the end is found
	bne 	appleWallCompareLoop

	b 		appleDrawLoop	// If the both are equal (x,y) then get some new coordinates from RNG

// This will do the same thing for the snake array
appleSnakeCompare:
	@ convert cell coordinates to pixel coordinates
	lsl		r4, #5
	lsl		r5, #5

	@@@@@@ GET SNAKE INFO @@@@@@
	ldr		r0, =snakeTail
	ldr		r1, [r0]				@ tail pointer

	ldr		r0, =snakeHead
	ldr		r2, [r0]				@ head pointer

	ldr		r3, =snakeQueue
	add		r3, #188				@ points to end of queue

	@@@@@@ CHECK HEAD @@@@@@
	@ load coordinates of head cell
	ldr		r0, [r2, #-4]
	ldr		r6, [r2]

	cmp		r4, r0					@ check X coordinate
	bne		appleSnakeCompareLoop

	cmp		r5, r6					@ check Y coordinate
	beq		appleDrawLoop			@ collision detected

appleSnakeCompareLoop:
	@ load coordinates of body cell
	ldr		r0, [r1], #4
	ldr		r6, [r1], #4

	@ wrap tail pointer
	cmp		r1, r3
	ldrge	r1, =snakeQueue

	@ check if all body cells have been checked yet (tp == hp)
	sub		r2, #4
	cmp		r1, r2
	add		r2, #4
	beq		appleValuePackCompare

	cmp		r4, r0
	bne		appleSnakeCompareLoop

	cmp		r5, r6
	beq		appleDrawLoop

	b 		appleSnakeCompareLoop

appleValuePackCompare:
	ldr		r0, =valueItem
	ldr		r1, [r0]
	ldr		r2, [r0, #4]

	cmp		r4, r1
	bne		drawAppleImage

	cmp		r5, r2
	bne		drawAppleImage

	b		appleDrawLoop

// This will draw the apple if the coordinates make it past the brute force checks.
drawAppleImage:
	ldr 	r0, =applePlace
	str		r4, [r0]
	str		r5,	[r0, #4]

	ldr 	r0, =applesEaten
	ldr	 	r0, [r0]
	cmp 	r0, #20
	bge 	drawDoorImage

	ldr 	r0, =appleImage	// Load the apple image
	mov 	r1, r4			// Move x into r1 to draw at that coord
	mov 	r2, r5			// Move y into r2 to draw at that coord
	bl 		Draw_Image		// Draw the apple image at (x,y)
	b 		drawAppleEnd

drawDoorImage:
	ldr 	r0, =doorImage	// Load the door image
	mov 	r1, r4		    // Move x into r1 to draw at that coord
	mov 	r2, r5			// Move y into r2 to draw at that coord
	bl 		Draw_Image		// Draw the door image at (x,y)
	b 		drawAppleEnd

drawAppleEnd:
	pop {r4-r6, pc}




// ------------------------------------------------------ Subroutine for spawning the drill valuepack. ---------------------------------------------------------
Spawn_ValuePack:
	push	{r4-r6, lr}					@ save link register to stack

	// The loop for the value pack coordinate RNG
valuePackRandLoop:
	bl		rand			// generates a random number based on system state for x
	lsr		r0, #1			// makes sure integer is unsigned ( > 0)
	mov 	r1, #29 		// The range for the x to be bounded by
	bl 		sdiv
	add 	r1, #1			// Increment the x by one to stay within the bounds
	mov 	r4, r1 			// Storing what the temp x value will be

	bl		rand			// generates a random number based on system state for y
	lsr		r0, #1			// makes sure integer is unsigned ( > 0)
	mov 	r1, #21	 		// The range for the y to be bounded by
	bl 		sdiv
	add 	r1, #1			// Increment the y by one to stay within the bounds
	mov 	r5, r1 			// Storing what the temp y value will be

valuePackWallCompare:
	ldr 	r6, =levelOneWalls

// 	The loop to compare all elements in the wall to the RNG coordinate
valuePackWallCompareLoop:
	ldr 	r0, [r6]		// Load the x
	cmp 	r0, #-1			// Check for the end of the array
	beq 	valuePackSnakeCompare
	cmp 	r0, r4			// Check if they "conflict"
	addne 	r6, #8			// Go to the next x if not equal
	bne 	valuePackWallCompareLoop

	add 	r6, #4			// If they are equal, then go to the related y
	ldr 	r0, [r6]		// load the y
	cmp 	r0, r5			// Check if the two y's are the same
	addne 	r6, #4			// If not equal, go to the next x and return to loop until the end is found
	bne 	valuePackWallCompareLoop

	b 		valuePackRandLoop	// If the both are equal (x,y) then get some new coordinates from RNG

// This will do the same thing for the snake array
valuePackSnakeCompare:
	@ convert cell coordinates to pixel coordinates
	lsl		r4, #5
	lsl		r5, #5

	@@@@@@ GET SNAKE INFO @@@@@@
	ldr		r0, =snakeTail
	ldr		r1, [r0]				@ tail pointer

	ldr		r0, =snakeHead
	ldr		r2, [r0]				@ head pointer

	ldr		r3, =snakeQueue
	add		r3, #188				@ points to end of queue

	@@@@@@ CHECK HEAD @@@@@@
	@ load coordinates of head cell
	ldr		r0, [r2, #-4]
	ldr		r6, [r2]

	cmp		r4, r0					@ check X coordinate
	bne		valuePackSnakeCompareLoop

	cmp		r5, r6					@ check Y coordinate
	beq		valuePackRandLoop		@ collision detected

valuePackSnakeCompareLoop:
	@ load coordinates of body cell
	ldr		r0, [r1], #4
	ldr		r6, [r1], #4

	@ wrap tail pointer
	cmp		r1, r3
	ldrge	r1, =snakeQueue

	@ check if all body cells have been checked yet (tp == hp)
	sub		r2, #4
	cmp		r1, r2
	add		r2, #4
	beq		valuePackAppleCompare

	cmp		r4, r0
	bne		valuePackSnakeCompareLoop

	cmp		r5, r6
	beq		valuePackRandLoop

	b 		valuePackSnakeCompareLoop

valuePackAppleCompare:
	ldr		r0, =applePlace
	ldr		r1, [r0]
	ldr		r2, [r0, #4]

	cmp		r4, r1
	bne		renderValuePack

	cmp		r5, r2
	bne		renderValuePack

	b		valuePackRandLoop

// This will draw the value if the coordinates make it past the brute force checks.
renderValuePack:
	ldr 	r0, =valueItem
	str		r4, [r0]
	str		r5,	[r0, #4]

	ldr 	r0, =drillImage	// Load the value pack image
	mov 	r1, r4			// Move x into r1 to draw at that coord
	mov 	r2, r5			// Move y into r2 to draw at that coord
	bl 		Draw_Image		// Draw the apple image at (x,y)

spawnValuePackEnd:
	pop		{r4-r6, pc}					@ return to calling code









//----------------------------------- The subroutine used to pause the game from the pause menu.--------------------------------------------------
pauseGame:

	push {r4-r7, lr}

@@@@@@ 		DRAW MENU IMAGE 		@@@@@@
    ldr		r0, =pauseMenu
    mov		r1, #172
    mov		r2, #124
	bl		Draw_Image

@@@@@@ 		DRAW INDICATOR 			@@@@@@
	ldr		r0, =pauseArrow
	mov		r1, #220
	mov		r2, #280
	bl		Draw_Image

	mov		r4, #1						@ menu state register
	mov		r5, #0						@ previous button states

	@ load current system time for deboucning
	ldr		r7, =0x20003004
	ldr		r7, [r7]
	ldr		r0, =1000000
	add		r7, r0

pauseLoop:

	bl		Read_SNES					@ Get SNES controller state
	mov		r6, r0						@ save current button states

	bic		r0, r5						@ set newly pushed butons in r0
	mov		r5, r6						@ save previous button states

	tst		r0, #32						@ check if down arrow was pushed
	bne		pauseFlipSelection			@ change what the indicator is pointing to

	tst		r0, #16						@ check if up arrow was pushed
	bne		pauseFlipSelection			@ change what the indicator is pointing to

	tst		r0, #256					@ check if A pressed
	bne		selectPauseItem				@ decide whether to play or quit

@@@@@@ CHECK IF START BUTTON WAS PRESSED @@@@@@
	ldr		r1, =0x20003004
	ldr		r1, [r1]

	cmp		r1, r7
	blt		pauseLoop

	tst		r0, #8
	movne	r0, #3
	bne		returnPause

	b		pauseLoop

pauseFlipSelection:
	eor		r4, #1						@ flip button state

@@@@@@ 		REDRAW SCREEN 		@@@@@@
	ldr		r0, =pauseMenu
	mov		r1, #172
	mov		r2, #124
	bl 		Draw_Image

	tst		r4, #1

@@@@@@ 		DRAW INDICATOR IN APPROPIATE POSITION 		@@@@@@
	ldr		r0, =pauseArrow
	mov		r1, #220
	movne	r2, #280
	moveq	r2, #440
	bl		Draw_Image

	b		pauseLoop

selectPauseItem:
	tst		r4, #1
	movne	r0, #0						@ set return to restart game
	moveq	r0, #1						@ set return to return to main menu

returnPause:
	pop {r4-r7, pc}






// --------------------------------------------- The controller of our main game logic. Uses other subroutines provided. -------------------------------------------------
// --------------------------------------------- Mainly manages the movement of the snake, as well as spawning and drawing. ----------------------------------------------
mainGameLogic:
	push	{r4-r10, lr}

initGameLoop:
@@@@@@ CLEAR SCREEN @@@@@@
	mov		r0, #0
	mov		r1, #0
	mov		r2, #0
	mov		r3, #1024
	mov		r4, #768
	push	{r4}
	bl		Draw_Rect
	add		sp, #4

@@@@@@ INITIALIZE GAME STATE @@@@@@
	@ reset score
	ldr		r0, =score
	mov		r1, #0
	str		r1, [r0]

	@ reset number of lives
	ldr		r0, =lives
	mov		r1, #3
	str		r1, [r0]

	@ reset number of apples eaten
	ldr		r0, =applesEaten
	mov		r1, #0
	str		r1, [r0]

	@ reset value pack
	ldr		r0, =valueItem
	mov		r1, #-1
	str		r1, [r0]
	str		r1, [r0, #4]
	mov		r1, #0
	str		r1, [r0, #8]

	ldr		r0, =activeValuePack
	mov		r1, #-1
	str		r1, [r0]

	@ load and copy original map
	ldr		r0, =levelOneWallsStatic
	ldr		r1, =levelOneWalls

loadMapLoop:
	ldr		r2, [r0], #4
	str		r2, [r1], #4

	cmp		r2, #-1
	bne		loadMapLoop


	bl		Draw_Map					@ render the map

@@@@@@ DRAW SCORE AND LIVES TEXT @@@@@@
	ldr		r0, =scoreImage
	mov		r1, #300
	mov		r2, #740
	bl		Draw_Image

	ldr		r0, =livesImage
	mov		r1, #624
	mov		r2, #740
	bl		Draw_Image

initSnake:
	bl		updateStats					@ Render score and lives to screen
	bl		Disable_Timer_IRQ			@ Make sure value packs do not spawn until later

	ldr		r4, =snakeQueue				@ r4 always points to the tail
	add		r5, r4, #20					@ r5 always points to the head
	add		r6, r4, #188				@ r6 points to the end of the snake queue

@@@@@@	LOAD INITIAL SNAKE	@@@@@@
	mov		r1, #512
	mov		r2, #288
	str		r1, [r4]
	str		r2, [r4, #4]

	mov		r2, #320
	str		r1, [r4, #8]
	str		r2, [r4, #12]

	mov		r2, #352
	str		r1, [r4, #16]
	str		r2, [r4, #20]

	@ store snake head
	ldr		r0, =snakeHead
	str		r5, [r0]

	@ store snake tail
	ldr		r0, =snakeTail
	str		r4, [r0]

	@ spawn initial apple
	bl		Spawn_Apple

@@@@@@		DRAW INITIAL SNAKE @@@@@@
	ldr		r0, =headImage
	ldr		r1, [r5, #-4]
	ldr		r2, [r5]
	bl		Draw_Image

	ldr		r0, =bodyImage
	ldr		r1, [r5, #-12]
	ldr		r2, [r5, #-8]
	bl		Draw_Image

	ldr		r0, =bodyImage
	ldr		r1, [r5, #-20]
	ldr		r2, [r5, #-16]
	bl		Draw_Image

@@@@@@	WAIT FOR USER INPUT TO BEGIN  @@@@@@
	ldr		r0, =1000000
	bl		Wait

waitForInput:
	bl		Read_SNES
	cmp		r0, #0
	beq		waitForInput

	@ set value pack item to spawn in random amount of time
	bl		rand
	lsr		r0, #1					@ make sure random time is an unsigned int

	ldr		r1, =20000000			@ maximum amount of time to spawn is 30 seconds
	bl		sdiv					@ compute (rand % 20s) + 10s

	ldr		r0, =10000000			@ minimum amount of time to spawn is 10 seconds
	add		r3, r1, r0

	bl		Enable_Timer_IRQ		@ enable timer IRQ's for value pack spawning

	mov		r0, r3					@ set time to wait in r0
	ldr		r1, =Spawn_ValuePack	@ set handler function
	bl		Wait_Async				@ set timer interrupt

	mov		r9, #0					@ previous button states
	mov		r7, #16					@ store current movement direction (default down)
									@ 32 is up 16 is down 64 is right and 128 is left
gameLoop:
	bl		Read_SNES
	bic		r10, r0, r9
	mov		r9, r0
	bic		r0, r7					@ prevents snake from going in the opposite direction

pauseTrigger:
    tst   	r10, #8
    beq		skipPause

    mov		r9, #8					@ start debouncing

    push	{r0}					@ save r0 which holds controller input needed for snake movement to stack

    bl		Disable_Timer_IRQ		@ disable value pack spawning while paused

    bl		pauseGame
    tst		r0, #1
    addeq	sp, #4					@ reclaim stack space from pushing r0
    beq		initGameLoop			@ restart game

    tst		r0, #2

    pop		{r0}					@ restore r0 from stack
    bne		clearPause				@ continue (user pressed start button to return)

    @ return to main menu (user selected quit option)
    pop		{r4-r10, lr}
    b		initializeGame

clearPause:
	// need to save r0 (which contains D-pad commands) before calling other functions
	push	{r0}

@@@@@@ REDRAW MAP @@@@@@
	bl		Draw_Map

@@@@@@ REDRAW APPLE @@@@@@
	@ determine if we are drawing an apple or a door
	fat:
	ldr		r0, =applesEaten
	ldr		r0, [r0]
	cmp		r0, #20

	ldrlt	r0, =appleImage
	ldrge	r0, =doorImage

	ldr		r3, =applePlace
	ldr		r1, [r3]
	ldr		r2, [r3, #4]
	bl		Draw_Image

@@@@@@ REDRAW VALUE PACK @@@@@@
	ldr		r0, =drillImage
	ldr		r3, =valueItem
	ldr		r1, [r3]
	ldr		r2, [r3, #4]
	cmp		r1, #-1
	blne	Draw_Image

@@@@@@ REDRAW SNAKE @@@@@@
	// Re-draw snake head
	ldr		r0, =headImage
	ldr		r1, [r5, #-4]
	ldr		r2, [r5]
	bl		Draw_Image

	// store current tail pointer on stack
	push	{r4}
	sub		r5, #4

snakeRedrawLoop:
	ldr		r0, =bodyImage
	ldr		r1, [r4], #4
	ldr		r2, [r4], #4
	bl		Draw_Image

	cmp		r4, r6
	ldrge	r4, =snakeQueue

	cmp		r4, r5
	bne		snakeRedrawLoop

	// restore tail pointer from stack
	add		r5, #4
	pop		{r4}

	bl		Enable_Timer_IRQ		@ enable timer IRQ's for value pack spawning

	@ check if a value pack is active dont spawn if active
	ldr		r0, =activeValuePack
	ldr		r0, [r0]
	cmp		r0, #-1
	popne	{r0}
	bne		skipPause

	@ check if a value pack is already on map dont spawn if already on map
	ldr		r0, =valueItem
	ldr		r0, [r0]
	cmp		r0, #-1
	popne	{r0}
	bne		skipPause


	@ set value pack item to spawn in random amount of time
	bl		rand
	lsr		r0, #1					@ make sure random time is an unsigned int

	ldr		r1, =20000000			@ maximum amount of time to spawn is 30 seconds
	bl		sdiv					@ compute (rand % 20s) + 10s

	ldr		r0, =10000000			@ minimum amount of time to spawn is 10 seconds
	add		r3, r1, r0

	mov		r0, r3					@ set time to wait in r0
	ldr		r1, =Spawn_ValuePack	@ set handler function
	bl		Wait_Async				@ set timer interrupt

	pop		{r0}					@ restore movement commands from stack

skipPause:
	@ load snake head coordinates
	ldr		r1, [r5, #-4]
	ldr		r2, [r5]

	@ advance snake head pointer and wrap queue
	add		r5, #8
	cmp		r5, r6
	ldrgt	r5, =snakeQueue
	addgt	r5, #4

@@@@@@ 	NO D-Pad PRESSED @@@@@@
	tst		r0, #240
	bne		snakeMove

@ compute correct current direction (uninvert)
	mov		r0, r7
	tst		r0, #160
	lsleq	r0, #1
	lsrne	r0, #1

snakeMove:
@@@@@@		MOVE UP			@@@@@@
	tst		r0, #16
	subne	r2, #32
	movne	r7, #32
	bne		checkCollisions

@@@@@@		MOVE DOWN		@@@@@@
	tst		r0, #32
	addne	r2, #32
	movne	r7, #16
	bne		checkCollisions

@@@@@@		MOVE LEFT		@@@@@@
	tst		r0, #64
	subne	r1, #32
	movne	r7, #128
	bne		checkCollisions

@@@@@@		MOVE RIGHT		@@@@@@
	tst		r0, #128
	addne	r1, #32
	movne	r7, #64
	bne		checkCollisions

checkCollisions:
@@@@@@ COLLISION DETECTION @@@@@@

	@ boundary detection
	cmp		r1, #0
	beq		collisionDetected

	cmp		r1, #992
	beq		collisionDetected

	cmp		r2, #0
	beq 	collisionDetected

	cmp		r2, #704
	beq		collisionDetected

	@ wall detection
	ldr		r0, =levelOneWalls

checkWalls:
	@ load wall cell coordinates
	ldr		r3, [r0], #4
	ldr		r8, [r0], #4

	@ wall array is terminated with a -1
	cmp		r3, #-1
	beq		checkSnakeCollisions

	@ convert cell coordinates to screen coordinates
	lsl		r3, #5
	lsl		r8, #5

	cmp		r1, r3
	bne		checkWalls

	cmp		r2, r8
	bne		checkWalls

	// collision with wall detected at this point
	// check for active drill value pack
	mov		r10, r0					@ save position in wall array
	ldr		r0, =activeValuePack
	ldr		r3, [r0]

	cmp		r3, #-1
	beq		collisionDetected

	// active drill value pack at this point
	push	{r1, r2}				@ need to save snake head coordinates

	// clear wall cell from array
	mov		r1, #-2					@ -2 represents a cleared wall cell
	str		r1, [r10, #-8]
	str		r1, [r10, #-4]

	// clear drill value pack in stats indicator
	mov		r1, #-1
	str		r1, [r0]

	mov		r0, #0
	mov		r1, #512
	mov		r2, #736
	mov		r3, #32
	push	{r3}
	bl		Draw_Rect
	add		sp, #4

	// set new value pack item to spawn in random amount of time
	bl		rand
	lsr		r0, #1					@ make sure random time is an unsigned int

	ldr		r1, =20000000			@ maximum amount of time to spawn is 30 seconds
	bl		sdiv					@ compute (rand % 20s) + 10s

	ldr		r0, =10000000			@ minimum amount of time to spawn is 10 seconds
	add		r3, r1, r0

	mov		r0, r3					@ set time to wait in r0
	ldr		r1, =Spawn_ValuePack	@ set handler function
	bl		Wait_Async				@ set timer interrupt

	pop		{r1, r2}				@ restore proposed snake head coordinates

checkSnakeCollisions:
	@ save r4 to stack
	push	{r4}

snakeCollisionLoop:
	@ load coordinates of body cell
	ldr		r3, [r4], #4
	ldr		r8, [r4], #4

	@ wrap tail pointer
	cmp		r4, r6
	ldrge	r4, =snakeQueue

	@ check if all body cells have been checked yet (tp == hp)
	sub		r0, r5, #4
	cmp		r4, r0
	beq		doneSnakeCollisions

	cmp		r1, r3
	bne		snakeCollisionLoop

	cmp		r2, r8
	beq		collisionDetected

	b 		snakeCollisionLoop

doneSnakeCollisions:
	@ restore r4
	pop		{r4}


	@ no collisions detected
	b		renderSnake

collisionDetected:
@ decrement lives
	ldr		r0, =lives
	ldr		r1, [r0]
	sub		r1, #1
	str		r1, [r0]

	@ render score and lives to screen
	bl		updateStats

	@ check lose condition
	ldr		r0, =lives
	ldr		r0, [r0]
	cmp		r0, #0
	beq		gameLost

	bl		Draw_Map				@ Redraw map

	b		initSnake				@ Reinitialize the snake

renderSnake:
@ push new head coordinates to queue
	str		r1, [r5, #-4]
	str		r2, [r5]

@ draw the new head and draw a body cell where the old head was
	ldr		r0, =headImage
	bl		Draw_Image

	@ check if queue just wrapped around to keep track of previous head
	sub		r3, r5, #4
	ldr		r0, =snakeQueue
	cmp		r3, r0

	ldrne	r1, [r5, #-12]
	ldrne	r2, [r5, #-8]

	ldreq	r1, [r6, #-4]
	ldreq	r2, [r6]

	ldr		r0, =bodyImage
	bl		Draw_Image



	@ store snake head
	ldr		r0, =snakeHead
	str		r5, [r0]

	@ store snake tail
	ldr		r0, =snakeTail
	str		r4, [r0]

@@@@@@ CHECK IF VALUE PACK WAS EATEN @@@@@@
	ldr		r0, [r5, #-4]
	ldr		r1, [r5]

	ldr		r3, =valueItem
	ldr		r2, [r3]
	ldr		r3, [r3, #4]

	cmp		r0, r2
	bne		valuePackNotEaten
	cmp		r1, r3
	bne		valuePackNotEaten

	// value pack was eaten at this point store active value pack type
	ldr		r0, =activeValuePack
	ldr		r1, =valueItem
	ldr		r1, [r1, #8]
	str		r1, [r0]

	// erase value pack coordinates from screen
	ldr		r0, =valueItem
	mov		r1, #-1
	str		r1, [r0]
	str		r1, [r0, #4]

	// increment score
	ldr		r0, =score
	ldr		r1, [r0]
	add		r1, #1
	str		r1, [r0]

	bl 		updateStats

	// draw value pack at stats indicator
	ldr		r0, =drillImage
	mov		r1, #512
	mov		r2, #736
	bl		Draw_Image

valuePackNotEaten:
@@@@@@ CHECK IF APPLE WAS EATEN @@@@@@
	ldr		r0, [r5, #-4]
	ldr		r1, [r5]

	ldr		r3, =applePlace
	ldr		r2, [r3]
	ldr		r3, [r3, #4]

	cmp		r0, r2
	bne		appleNotEaten
	cmp		r1, r3
	bne		appleNotEaten

	@ update the number of apples eaten
	ldr		r0, =applesEaten
	ldr		r1, [r0]
	add		r1, #1
	str		r1, [r0]

	@ update game score
	ldr		r0, =score
	ldr		r1, [r0]
	add		r1, #3
	str		r1, [r0]

	@ check win condition
	ldr		r0, =applesEaten
	ldr		r0, [r0]
	cmp		r0, #21
	beq		gameWon

	@ render score and lives to screen
	bl		updateStats

	bl		Spawn_Apple
	b		gameLoopCycleEnd

appleNotEaten:
@ clear the tail and pop the coordinates from the queue
	ldr		r1, [r4]
	ldr		r2, [r4, #4]
	ldr		r0, =floorImage
	@mov		r3, #32
	@push	{r3}
	bl		Draw_Image
	@add		sp, #4

	add		r4, #8
	cmp		r4, r6
	ldrge	r4, =snakeQueue

gameLoopCycleEnd:
	ldr		r0, =100000
	bl		Wait

	b 		gameLoop

gameWon:
	@ disable value pack spawning
	bl		Disable_Timer_IRQ

	@ draw game won splash
	ldr		r0, =gameWonImage
	mov		r1, #172
	mov		r2, #124
	bl		Draw_Image

	@ pause for at least a second
	ldr		r0, =500000
	bl		Wait

	@ wait for user input to return to main menu
	bl		Read_SNES
	cmp		r0, #0
	beq		gameWon

	pop		{r4-r10, lr}

	@ return to main menu
	b		initializeGame

gameLost:
	@ disable value pack spawning
	bl		Disable_Timer_IRQ

	@ draw game over splash
	ldr		r0, =gameOverImage
	mov		r1, #172
	mov		r2, #124
	bl		Draw_Image

	@ pause for at least a second
	ldr		r0, =1000000
	bl		Wait

	@ wait for user input to return to main menu
	bl		Read_SNES
	cmp		r0, #0
	beq		gameLost

	pop		{r4-r10, lr}

	@ return to main menu
	b		initializeGame

	pop		{r4-r10, pc}











//--------------------------------------- Initializations and general start of the program. Moves from menu to the mainGameLogic function --------------------------------------------
main:
    bl      Install_Interrupt_Table     @ Load IVT into memory
    push    {r4-r6}
    bl	    EnableJTAG
    bl	    InitUART

    bl      Init_SNES                   @ Initialize the SNES controller


    bl      Enable_Interrupts			@ Globally enable interrupts

    bl		InitFrameBuffer				@ Get GPU to setup framebuffer

initializeGame:
@@@@@@ 		DRAW MENU IMAGE 		@@@@@@
    ldr		r0, =menuImage
    mov		r1, #0
    mov		r2, #0
	bl		Draw_Image

@@@@@@ 		DRAW INDICATOR 			@@@@@@
	ldr		r0, =arrowImage
	mov		r1, #220
	mov		r2, #324
	bl		Draw_Image

	mov		r4, #1						@ menu state register
	mov		r5, #256					@ previous button states (default A to debounce A when returning to main menu)

	@ more debouncing
	ldr		r0, =1000000
	bl		Wait

menuLoop:
	bl		Read_SNES					@ Get SNES controller state
	mov		r6, r0						@ save current button states

	bic		r0, r5						@ set newly pushed butons in r0
	mov		r5, r6						@ save previous button states

	cmp		r0, #0						@ check if any buttons were pressed
	beq		menuLoop					@ loop until buttons pressed

	tst		r0, #32						@ check if down arrow was pushed
	bne		flipSelection				@ change what the indicator is pointing to

	tst		r0, #16						@ check if up arrow was pushed
	bne		flipSelection				@ change what the indicator is pointing to

	tst		r0, #256					@ check if A pressed
	bne		selectMenuItem				@ decide whether to play or quit

	b		menuLoop

flipSelection:
	eor		r4, #1						@ flip button state

	@@@@@@ 		REDRAW SCREEN 		@@@@@@
	ldr		r0, =menuImage
	mov		r1, #0
	mov		r2, #0
	bl 		Draw_Image

	tst		r4, #1

	@@@@@@ 		DRAW INDICATOR IN APPROPIATE POSITION 		@@@@@@
	ldr		r0, =arrowImage
	mov		r1, #220
	movne	r2, #324
	moveq	r2, #440
	bl		Draw_Image

	b		menuLoop

selectMenuItem:
	tst		r4, #1
	bne		mainGameLogic

quitGame:
@@@@@@	DRAW BLACK SCREEN AND HALT @@@@@@
	mov		r0, #0
	mov		r1, #0
	mov		r2, #0
	mov		r3, #1024
	mov		r4, #768
	push	{r4}
	bl		Draw_Rect
	add		sp, #4
  pop {r4-r6}
haltLoop:
    b   haltLoop


.section .data

// A "level one" set of coordinates of Wall tiles. (Organized as (x,y), (x,y), ... ) with the last element (-1) showing when it ends

// This has 15 coordinates of blocks
// This static copy never changes
levelOneWallsStatic: 	.word 17, 2,     17, 6,     17, 8,     17, 10,     4, 5,   4, 6,   4, 7,   4, 8,   10, 15,   11, 15,   12, 15,   12, 16,   12, 17,   12, 18,   25, 5,   25, 6,    25, 7,    27, 7,   29, 7, 			-1

// This copy can change to make the map dynamic
levelOneWalls: 	.word 17, 2,     17, 6,     17, 8,     17, 10,     4, 5,   4, 6,   4, 7,   4, 8,   10, 15,   11, 15,   12, 15,   12, 16,   12, 17,   12, 18,   25, 5,   25, 6,    25, 7,    27, 7,   29, 7, 			-1

// Where the apple / door is
applePlace: 	.word 0, 0

// The amount of apples that have been eaten
applesEaten:	.word 0

// Array of number images
numberSpriteArray: .word zeroSprite, oneSprite, twoSprite, threeSprite, fourSprite, fiveSprite, sixSprite, sevenSprite, eightSprite , nineSprite

// Information on the value pack items
valueItem:
	.word	-1, -1		// (x,y) coordinates of the current value pack item
	.word	0			// type of value pack

// Keeps track of which value pack abillities are enabled
activeValuePack:	.word	-1

// Keeps the score of the user (Equal to 2 * length - 6 (because of staring at 3))
score:			.word 0

// The amount of lives remaining
lives:			.word 0

// The array that holds all the coordinates of the snake. Enough for a snake length of 100
snakeQueue:
.rept	8 * 24
.byte	0
.endr

snakeHead:	.word 0
snakeTail:	.word 0
