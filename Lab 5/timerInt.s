.section .exceptions, "ax"
	addi sp, sp, -8
	stw r2, 0(sp)
	stw r4, 4(sp)
	
	#toggle LED 3
	movia r2, 0xff200000
	ldwio r4, 0(r2)
	xori r4, r4, 0x8
	stwio r4, 0(r2)
	
	#ACK Timer Interrupt
	movia r2, 0xff202000
	movi r4, 1
	stwio r4, 0(r2) #clear Status TO bit
	
	ldw r4, 4(sp)
	ldw r2, 0(sp)
	addi sp, sp, 8
	
	addi ea, ea, -4
	eret
.text
.global _start
_start:
	movia sp, 0x200000
	call timerIntEnable
	call buttonsEdgeReset
	#call button0IntEnable
	
loop:
	call led0toggle
	call button0wait
	br loop

led0toggle: 
	movia r5, 0xff200000
	ldwio r2, 0(r5)
	xori r2, r2, 1
	stwio r2, 0(r5)
	ret

waitasec:
	movia r4, 0xff202000
	movia r5, 100000000
	movi r2, 0x8
	stwio r0, 0(r4) # clear TO
	stwio r2, 4(r4) # stop timer
	stwio r5, 8(r4) # periodlo
	srli r5, r5, 16
	stwio r5, 12(r4) # periodhi
	movi r2, 0x4
	stwio r2, 4(r4)
bwait:
	ldwio r2, 0(r4)
	andi r2, r2, 0x1 # check TO
	beq r2, r0, bwait
	
	ret
	
buttonsEdgeReset:
	movia r2, 0xff200050 #buttons
    movi r4, 0xF
	stwio r4, 12(r2)
	ret

button0wait:
	movia r2, 0xff200050 #buttons
b0wbwait:
	ldwio r4, 12(r2) # check button 0
	andi r4,r4, 1   
	beq r4, r0, b0wbwait
	stwio r4, 12(r2) # clear EDGE bit 0
	ret

button0IntEnable:
	movia r2, 0xff200050 #buttons
	movi r4, 0x1
	stwio r4, 12(r2) # reset EDGE bit
	stwio r4, 8(r2)
	movi r5, 0x2
	wrctl ctl3, r5 # enable ints for IRQ1/buttons
	wrctl ctl0, r4 # enable ints globally
	ret
	
timerIntEnable:
	#DEVICE SIDE
	movia r4, 0xff202000
	movia r5, 100000000
	movi r2, 0x8 # stop it
	stwio r0, 0(r4) # clear TO
	stwio r2, 4(r4) # stop timer
	stwio r5, 8(r4) # periodlo
	srli r5, r5, 16
	stwio r5, 12(r4) # periodhi

    movi r2, 0x7 # START | CONT | ITO
	stwio r2, 4(r4)

    # CPU SIDE
	movi r4, 0x1
	wrctl ctl3, r4 # enable ints for IRQ0/timer
	wrctl ctl0, r4 # enable ints globally
	ret
