.global _start
_start:

	.equ LEDs, 0xFF200000
	.equ BUTTONs, 0xFF200050
	
	movi r6, 0 # Store value of the output
	movi r5, 15 # Max output
	
	movi r10, 1
	movi r11, 2
	movi r12, 4
	movi r13, 8
	
ButtonToggleLED:
	movia r8, LEDs
	movia r9, BUTTONs
	stwio r0, 0(r8) #turn off all LEDs, write 0 to LED PIT DR

FEVER: #polling, constantly check for press

      ldwio r2, 12(r9) #read BUTTON PIT EDGE
      beq r2, r0, FEVER # not pressed yet, keep checking

pressed:   
     # ldwio r4, 0(r8) # read LED DR (current status)
     # xori r4, r4, 1 # toggle led 0
	  
	  beq r2, r10, KEY0
	  beq r2, r11, KEY1
	  beq r2, r12, KEY2
	  bge r2, r13, KEY3
	  
toggle:
      stwio r6, 0(r8) # change the LEDs (write to LED PIT DR)
      movi r2, 1 #      RESET bit 0 of BUTTON PIT EDGE
      stwio r2, 12(r9) # write the DR of the LED PIT
      br FEVER
	

KEY0:
	movi r6, 1
	br toggle

KEY1:
	bge r6, r5, FEVER #change nothing, keep polling because at upper limit
	addi r6, r6, 1
	br toggle
	

KEY2:
	ble r6, r0, FEVER #change nothing, keep polling because at lower limit 
	subi r6, r6, 1
	br toggle

KEY3:
	movi r6, 0
	br toggle
