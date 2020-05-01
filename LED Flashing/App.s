	AREA	AsmTemplate, CODE, READONLY
	IMPORT	main

; sample program makes the 4 LEDs P1.16, P1.17, P1.18, P1.19 go on and off in sequence
; (c) Mike Brady, 2011 -- 2019.

	EXPORT	start
start

IO1DIR	EQU	0xE0028018
IO1SET	EQU	0xE0028014
IO1CLR	EQU	0xE002801C
NUMBER 	EQU	0XB669FD2E
	
loop			LDR	R0,=IO1DIR
				LDR	R2,=0x000f0000	;select P1.19--P1.16
				STR	R2,[R0]			;make them outputs
				LDR	R1,=IO1SET
				STR	R2,[R1]			;set them to turn the LEDs off				
				LDR	R6,=IO1CLR
				LDR	R3,=0x00010000 	;Starting LED
				BL wait
				LDR R0, =NUMBER	;Number to convert and Display
				CMP R0, #0
				BEQ specialCaseZero
				LDR R5, =1			 ;Boolean leadingZeros? (If we encounter a zero is it a real digit or a leading zero)
				CMP R0, #0			 ;Check if our Number is negative				
				BGE notNegative	 	;Is Negative
				MOV R2, #13			;
				BL putBits
				BL wait
				LDR R3, =0x00010000
				BL twos
		 
notNegative		LDR R2, =1000000000 ;R2 = 1 Billion
				BL  calculateNumbers
				LDR R2, =100000000 ;R2 = 100 Million
				BL  calculateNumbers
				LDR R2, =10000000 ;R2 = 10 Million
				BL  calculateNumbers
				LDR R2, =1000000 ;R2 = 1 Million
				BL  calculateNumbers
				LDR R2, =100000 ;R2 = 100 Thousand
				BL  calculateNumbers
				LDR R2, =10000 ;R2 = 10 Thousand
				BL  calculateNumbers
				LDR R2, =1000 ;R2 = 1 Thousand
				BL  calculateNumbers
				LDR R2, =100 ;R2 = 1 Hundred
				BL  calculateNumbers
				LDR R2, =10 ;R2 = Ten
				BL  calculateNumbers
				LDR R2, =1 ;R2 = One
				BL  calculateNumbers
				B 	loop
			 
calculateNumbers
				PUSH {R4, LR}
				MOV R4, R2			;'Divisor'
				LDR R2, =0			; Counter
CalcLoop 		SUB R0, R0, R4		; Minus 'Divisor'
				CMP R0, #0			; Have we gone under 0?
				BLT negative		; Branch if we have gone negative
				ADD R2, R2, #1		; Counter++
				B 	CalcLoop
negative		ADD R0, R0, R4		; Add back R1 as we have underflowed
				CMP R2, #0			;
				BEQ checkZero		;
				LDR R5, =0			;We have encountered our first non-zero so all other zeros will be valid
				BL swapBits
validZero		BL putBits
				BL 	wait			;wait a second	
				LDR R3, =0x00010000				
leadingZero		POP {R4, PC}

checkZero 
				CMP R5, #1		;
				BNE setZero		;
				B 	leadingZero	;
setZero			
				MOV R2, #15		;
				B validZero
		 
putBits
				PUSH{R4-R5, LR}
				LDR  R4, =0		;reset counter
bitLoop	 		CMP  R4, #4		;4 bits
				BEQ done	 
				LDR  R5, =0		;Bit Checker		 
				MOVS R2, R2, LSR#1 ;Shift out the first bit of R4
				ADC  R5, R5, #0	;Check the bit
				ADD  R4, R4, #1	;Counter++
				CMP  R5, #1		;
				BEQ  turnOn		; Branch if the shifted bit is a 1
				STR R3, [R1]
				MOV R3, R3, LSL#1	;Next LED
				B bitLoop										;
turnOn			
				STR R3, [R6]		;Turn on the LED
				MOV R3,R3,LSL#1		;Next LED
				B bitLoop			;			
done	
				POP{R4-R5, PC}

wait
				PUSH{lr}
				ldr	r4,=16000000	;
dloop			subs	r4,r4,#1	;
				bne	dloop			;
				POP{PC}
	
swapBits
				push{R1, R3, lr}
				MOV R3, #4
				MOV R2, R2, LSL#28
				MOV R1, #0
swapLoop
				MOVS R2, R2, LSL#1
				RRX R1, R1
				SUBS R3, #1
				BNE swapLoop
				MOV R2, R1
				MOV R2, R2, LSR#28
				POP{R1, R3, pc}

twos			push{lr}
				LDR R2,=0xFFFFFFFF	;Bit mask
				EOR R0, R0, R2		;Invert the bits
				ADD R0, R0, #1		;Add 1
				POP{pc}
				
specialCaseZero
				MOV R2, #15
				BL putBits
				BL wait
				LDR	R2,=0x000f0000	;select P1.19--P1.16
				STR	R2,[R1]
				BL wait
				LDR R3, =0x00010000
				B specialCaseZero
				
stop	B	stop

	END