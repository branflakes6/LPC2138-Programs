	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

	EXPORT	start
start
		
IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
IO1PIN  EQU 0xE0028010
	
				;Main Program loop that constantly polls for button presses
				BL wait					;
				BL wait					;
				ldr R10,=0				;Number
				LDR R9, =0				;State Machine
				LDR R11,=2				;Operator
				LDR R8, =0				;Our Sum
				ldr	R1,=IO1DIR			;
				ldr	R2,=0x000f0000		;select P1.19--P1.16
				str	R2,[R1]				;make them outputs
				ldr	R1,=IO1SET			;
				str	R2,[R1]				;set them to turn the LEDs off 
detectPress		LDR R4, =0x00F00000		;Mask to detect a press
				LDR R0, =0				;
				LDR R7, =2				;
				LDR R5, =IO1PIN			;bit of all 4 buttons
				LDR R6, [R5]			;
				AND R6, R6, R4			;Check if any button is pressed
				CMP R6, R4				;
				BLNE findPressed		;A button has been pressed, determine which one				
				CMP R0, #23				;Button p.23 has been pressed
				BEQ nState				;
				CMP R0, #22				;Button p.22 has been pressed
				BEQ nState				;	
				LDR R7, =0				;
				CMP R0, #21				;Button p.21 has been pressed
				BEQ operatorState		;	
				LDR R7, =1				;
				CMP R0, #20				;Button p.20 has been pressed
				BEQ operatorState		;
				CMP R0, #-20			;Button p.20 has been pressed long pressed
				BEQ reset				;
				CMP R0, #-21			;Button p.21 has been pressed long pressed
				BEQ undoLast			;
				B	detectPress			;Loop until a button is pressed
						
reset			B start					;	

undoLast		CMP R9, #0				;
				BEQ	reset				;
				LDR R10, =0				;
				LDR R11, =2				;
				LDR R9, =1				;
				BL clear				;
				BL wait					;
				B detectPress			;

				;Determine the state for n+/n-
nState			CMP R9,#0				;Are we in state 0?
				BNE notZeroN			;
				CMP R0, #23				;
				BLEQ addN
				CMP R0, #22				;
				BLEQ subN
				BL swapBits				;
				BL putBits				;
				B detectPress			;
				
notZeroN		CMP R9, #1				;Are we in state 1?
				BNE notOneN				;
				CMP R11, #2				;
				BEQ needOp				;
				BL clear				;
				LDR R10, =0				;Reset Number	
				LDR R9, =2				;state = 2
needOp			
				B detectPress			;

notOneN			CMP R9, #2				;
				BNE detectPress			;
				CMP R0, #23				;
				BLEQ addN				;
				CMP R0, #22				;
				BLEQ subN				;
				BL swapBits				;
				BL putBits				;
				B detectPress			;

operatorState	CMP R9, #0				;
				BNE notZeroOp			;
				MOV R8, R10				;
				MOV R11, R7				;
				LDR R9, =1				;
				B detectPress			;
				
notZeroOp		CMP R9, #1				;
				BNE notOneOp
				CMP R11, #2			;
				BNE skipThis			;
				MOV R11, R7			;
skipThis		
				BL swapBits				;
				BL putBits				;	
				B detectPress	
				
notOneOp		CMP R9, #2				;
				BNE detectPress			;
				CMP R11, #0				;
				BLEQ addition			;
				CMP R11, #1				;
				BLEQ subtraction		;
				BL swapBits				;
				BL putBits				;
				MOV R11, R7				;
				LDR R9, =1				;
				B detectPress	
				
addN			PUSH{LR}
				CMP R10, #7				;
				BEQ skipAdd				;
				ADD R10, R10, #1		;
skipAdd			POP{PC}
				
subN			PUSH{LR}
				CMP R10, #-8			;
				BEQ skipSub				;
				SUB R10, R10, #1		;
skipSub			POP{PC}
				
addition		PUSH{LR}	
				ADD R8, R10, R8			;
				MOV R10, R8				;
				POP{PC}
				
subtraction		PUSH{LR}
				SUB R8, R8, R10			;
				MOV R10, R8				;
				POP{PC}
											
findPressed		
				PUSH {R4-R6, LR}			
				LDR R4, =0x00700000		;Mask for p23
				LDR R6, [R5]			;
				AND R6, R6, R4			;
				CMP R6, R4				;
				BNE skip23
				MOV R0, #23				;
skip23			LDR R4, =0x00B00000		;Mask for p22
				LDR R6, [R5]			;
				AND R6, R6, R4			;
				CMP R6, R4				;
				BNE skip22
				MOV R0, #22				;
skip22			LDR R4, =0x00D00000		;Mask for p21
				LDR R6, [R5]			;
				AND R6, R6, R4			;
				CMP R6, R4				;
				BNE skip21
				MOV R0, #21				;
skip21			LDR R4, =0x00E00000		;Mask for p20
				LDR R6, [R5]			;
				AND R6, R6, R4			;
				CMP R6, R4				;
				BNE skip20
				MOV R0, #20				;
skip20			BL wait
				LDR R4, =0x00F00000	
				LDR R5, =IO1PIN			;bit of all 4 buttons
				LDR R6, [R5]			;
				AND R6, R6, R4			;Check if any button is pressed
				CMP R6, R4				;
				BNE longPress			;
				B finished				;				
longPress		NEG R0, R0				;
finished		POP {R4-R6, PC}			;
						
putBits			PUSH{R2-R5, LR}
				LDR  R3, =0x00010000
				LDR  R4, =0			;reset counter
bitLoop	 		CMP  R4, #4			;4 bits
				BEQ done	
				LDR  R5, =0			;Bit Checker		 
				MOVS R2, R2, LSR#1 ;Shift out the first bit of R4
				ADC  R5, R5, #0		;Check the bit
				ADD  R4, R4, #1		;Counter++
				CMP  R5, #1			;
				BEQ  turnOn			; Branch if the shifted bit is a 1
				STR R3, [R1]
				MOV R3, R3, LSL#1	;Next LED
				B bitLoop										;
turnOn			LDR R6, =IO1CLR	
				STR R3, [R6]		;Turn on the LED
				MOV R3,R3,LSL#1		;Next LED
				B bitLoop			;			
done			POP{R2-R5, PC}
								
swapBits		push{R1, R3, lr}
				MOV R2, R10			;Put our current Sum into R2 which we will return
				MOV R3, #4			;Number of bits to swap
				MOV R2, R2, LSL#28  ;Shift our bits to the 4 left-most bits
				MOV R1, #0			;Zero the 32bits we will be using
swapLoop		MOVS R2, R2, LSL#1  ;Shift out a bit of our number into the carry
				RRX R1, R1          ;RRX will shift the carry right into R1
				SUBS R3, #1 		;Minus from our bit counter
				BNE swapLoop		;Loop
				MOV R2, R1			;Put our answer back into R2
				MOV R2, R2, LSR#28	;Shift R2 right to put the bits back to the right-most bits
				POP{R1, R3, pc}	
				
wait			PUSH{R4, lr}
				ldr	r4,=5000000		;
dloop			subs	r4,r4,#1	;
				bne	dloop			;
				POP{R4, PC}								
clear				
				PUSH{R1, R2, lr}
				ldr	R2,=0x000f0000	;select P1.19--P1.16
				ldr	R1,=IO1SET		;R1 = set
				str	R2,[R1]			;set them to turn the LEDs off
				POP {R1, R2, pc}
				
				
				
stop	B	stop

	END