.equ LED_BASE, 0xFF200000       # LEDs base address
.equ BUTTON_BASE, 0xFF200050    # Buttons base address
.equ STACK_ADD, 0x200000		# Stack address
.equ TIMER0_BASE, 0xFF202000   	# Timer base address

.equ MAX_SECONDS, 8            # Maximum seconds before wrap-around
.equ MAX_HUNDREDTHS, 99         # Maximum hundredths of a second before incrementing seconds

/******************************************************************************
* Write an interrupt service routine
*****************************************************************************/
.section .exceptions, "ax"
IRQ_HANDLER:
	# save registers on the stack (et, ra, ea, others as needed)
	subi sp, sp, 16 # make room on the stack
	stw et, 0(sp)
	stw ra, 4(sp)
	stw r20, 8(sp)
	rdctl et, ctl4 # read exception type
	beq et, r0, SKIP_EA_DEC # not external?
	subi ea, ea, 4 # decrement ea by 4 for external interrupts
SKIP_EA_DEC:
	stw ea, 12(sp)
	andi r20, et, 0x2 # check if interrupt is from pushbuttons
	beq r20, r0, END_ISR # if not, ignore this interrupt
	call KEY_ISR # if yes, call the pushbutton ISR
END_ISR:
	ldw et, 0(sp) # restore registers
	ldw ra, 4(sp)
	ldw r20, 8(sp)
	ldw ea, 12(sp)
	addi sp, sp, 16 # restore stack pointer
	eret # return from exception
/*********************************************************************************
* set where to go upon reset
********************************************************************************/
.section .reset, "ax"
	movia r8, _start
	jmp r8
/*********************************************************************************
* Main program
********************************************************************************/
.text
.global _start

_start:
	movia   sp, STACK_ADD          # Initialize the stack pointer
	movia r7, RUN
	movia r8, LED_BASE          # LEDs
    movia r9, BUTTON_BASE       # Buttons (active low)
    movia r10, TIMER0_BASE      # Timer base address
    movi r11, COUNT                 # Counter for hundredths of a second
    movi r12, 0                 # Counter for seconds
    movi r13, 1                 # state (1: paused, 0:running)
	movi r4, MAX_SECONDS		# store max seconds in r4
	movi r5, MAX_HUNDREDTHS		# store max hundredths in r5
	call CONFIG_TIMER
	call CONFIG_KEYS
	
KEY_ISR:
    xori r13, r13, 0x1          # Toggle clock state
    stwio r14, 12(r9)           # Clear the Edge Capture register
    ret
	
TIMER_ISR:
	update:
    	call timer_delay            # Wait for 0.01 second
    	addi r11, r11, 1            # Increment hundredths of a second
    	bgt r11, r5, increment_seconds
    	br display_time

	increment_seconds:
    	movi r11, 0                 # Reset hundredths of a second
    	addi r12, r12, 1            # Increment seconds
    	blt r12, r4, display_time
    	movi r12, 0                 # Reset seconds when reaching max
		
	display_time:
    	slli r14, r12, 7            # Shift seconds left to position in the higher bits
   		or r14, r14, r11            # bitwise or to combine with hundredths (?)
    	stwio r14, 0(r8)            # Update LEDs
   
   ret
   
timer_delay:
	
	
CONFIG_TIMER:
	#DEVICE SIDE
	movia r4, 0xff202000
	movia r5, 250000000
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

CONFIG_KEYS:
    movia   r4, BUTTON_BASE       # Load base address of buttons into r4
	# Enable interrupts for all buttons by setting their corresponding bits in the interrupt mask register
    movi    r5, 0xF         # we have 4 buttons and want to enable interrupts for all
    stwio   r5, 8(r4)       # Write to interrupt mask register at offset
	# clear any pending button interrupts by writing to the edge capture register
    stwio   r5, 12(r4)   # Write to edge capture register at offset to clear it
	 #CTL3
     movi r5, 0x2   # button are connected to IRQ1 (2nd bit of ctl3)
     wrctl ctl3, r5 # enable ints for IRQ1/buttons
     #CTL0
     movi r4, 0x1
     wrctl ctl0, r4 # enable ints globally (bit 0)
	 ret
	
IDLE: br IDLE

.global COUNT
COUNT: .word 0x0
.global RUN
RUN:	.word 0x1
.end



