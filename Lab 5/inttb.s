# Demonstrates:
# 1. Polling 
# 2. Multi-device interrupts
#
# Uses polling to wait for press-and-release of button 0
# the main polling loop toggles LED 0
#
# Enabled interrupts for button 1 and timer
# The timer toggles the upper 4 LEDs (LED 9-6)
# Button 1 toggles LEDs 2 and 3 (3rd and 4th)
#
# A. MOshovos, ECE 243 2024
.section .exceptions, "ax"
	addi sp, sp, -12
	stw r2, 0(sp)
	stw r4, 4(sp)
	stw r5, 8(sp)
	
	# CHECK interrupt cause through ctl4
	# give priority to button
	# if both the button and the timer IRQs are on
	# we will handle the button firts, return 
	# then the timer IRQ will still be on causing another
	# call to the handler
	rdctl r5, ctl4
	andi r5, r5, 2
	bne r5, r0, wasbutton
wastimer:
	#toggle LEDs 9-6
	movia r2, 0xff200000
	ldwio r4, 0(r2)
	xori r4, r4, 0x3c0
	stwio r4, 0(r2)

timerack:
	#ACK Timer Interrupt
	movia r2, 0xff202000
	movi r4, 0
	stwio r4, 0(r2) #clear Status TO bit
    br ihepi

wasbutton:
	#toggle LED 3-2
	movia r2, 0xff200000
	ldwio r4, 0(r2)
	xori r4, r4, 0x0c
	stwio r4, 0(r2)

buttonack:
    # ACK BUTTON CLEAR EDGE BIT 1
	movia r2, 0xff200050
	movi r4, 0x2
	stwio r4, 12(r2)	
	
ihepi:
	ldw r5, 8(sp)
	ldw r4, 4(sp)
	ldw r2, 0(sp)
	addi sp, sp, 12
	
	addi ea, ea, -4
	eret
.text
.global _start
_start:
	movia sp, 0x200000
	call timerIntEnable
	call buttonsEdgeReset
	movi r4, 2
	call buttonMaskIntEnable
    call ledReset
	
loop:
	# toggle LED 0
    movi r4, 1
	call ledMaskToggle
	# wait for button 0
	movi r4, 0x1
	call buttonMaskWait
	br loop

ledMaskToggle: # r4 = LEDs to toggle mask
	movia r5, 0xff200000
	ldwio r2, 0(r5)  # toggle LED at position r4
	xor r2, r2, r4
	stwio r2, 0(r5)
	ret

ledReset:
	movia r2, 0xff200000
    stwio r0, 0(r2)
	ret
	
buttonsEdgeReset: # reset all edge bits
	movia r2, 0xff200050 #buttons
    movi r4, 0xF
	stwio r4, 12(r2)
	ret

buttonMaskWait: # r4 = Buttons Mask to wait for
	movia r2, 0xff200050 #buttons
bNwbwait:
	ldwio r5, 12(r2) # check button 0
	and r5, r5, r4 # was the button pressed?   
	beq r5, r0, bNwbwait
	stwio r5, 12(r2) # clear EDGE bit 0
	ret

buttonMaskIntEnable: # r4 button # 0...3
	movia r2, 0xff200050 #buttons
	stwio r4, 12(r2) # reset EDGE bits
	stwio r4, 8(r2)  # set mask bits
	rdctl r5, ctl3
	ori r5, r5, 2
	wrctl ctl3, r5 # enable ints for IRQ1/buttons
	movi r4, 1
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

    stwio r0, 0(r4) # clear TO
    movi r2, 0x7 # START | CONT | ITO
	stwio r2, 4(r4)

    # CPU SIDE
    rdctl r4, ctl3
	ori r4, r4, 1
    wrctl ctl3, r4 # enable ints for IRQ0/timer
	wrctl ctl0, r4 # enable ints globally
	ret
