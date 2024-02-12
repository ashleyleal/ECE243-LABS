.equ LED_BASE, 0xFF200000       # Base address for LEDs
.equ BUTTON_BASE, 0xFF200050    # Base address for buttons
.equ STACK_ADD, 0x200000        # Stack address
.equ TIMER0_BASE, 0xFF202000    # Timer base address

/******************************************************************************
 * Interrupt Service Routine
 *****************************************************************************/
.section .exceptions, "ax"
IRQ_HANDLER:
    # Adjust stack space for all used registers
    subi sp, sp, 88
    
    # Save registers on the stack
    stw et, 0(sp)
    stw ra, 4(sp)
    stw r20, 8(sp)
    stw r21, 12(sp)
    stw ea, 16(sp)
    stw r2, 20(sp)
    stw r4, 24(sp)
    stw r5, 28(sp)
    stw r6, 32(sp)
    stw r7, 36(sp)
    stw r8, 40(sp)
    stw r9, 44(sp)
    stw r10, 48(sp)
    stw r11, 52(sp)
    stw r12, 56(sp)
    stw r14, 60(sp)
    
    # Read exception type
    rdctl et, ctl4

    # Check if external interrupt
    beq et, r0, SKIP_EA_DEC
    subi ea, ea, 4
	

SKIP_EA_DEC:
    stw ea, 16(sp)

    # Determine interrupt source (button or timer)
	
	movi r4, 0b10
	movi r5, 0b01
	
	beq et, r4, HANDLE_BUTTON
	beq et, r5, HANDLE_TIMER
    br END_ISR

HANDLE_BUTTON:
    call KEY_ISR
    br END_ISR

HANDLE_TIMER:
    call TIMER_ISR
    br END_ISR

END_ISR:
    # Restore registers
    ldw r14, 60(sp)
    ldw r12, 56(sp)
    ldw r11, 52(sp)
    ldw r10, 48(sp)
    ldw r9, 44(sp)
    ldw r8, 40(sp)
    ldw r7, 36(sp)
    ldw r6, 32(sp)
    ldw r5, 28(sp)
    ldw r4, 24(sp)
    ldw r2, 20(sp)
    ldw ea, 16(sp)
    ldw r21, 12(sp)
    ldw r20, 8(sp)
    ldw ra, 4(sp)
    ldw et, 0(sp)
    addi sp, sp, 88
    eret

/*********************************************************************************
 * Set where to go upon reset
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
    movia sp, STACK_ADD          # Initialize the stack pointer
    movia r6, 0xF
    movia r7, RUN
    movia r8, LED_BASE           # LEDs
    movia r9, BUTTON_BASE        # Buttons (active low)
    movia r10, TIMER0_BASE       # Timer base address
    movi r11, COUNT              # Counter for hundredths of a second
    movi r12, 0                  # Counter for seconds
    call CONFIG_TIMER
    call CONFIG_KEYS
    br IDLE

KEY_ISR:
	# Save ra
	subi sp, sp, 4
    stw ra, 0(sp)
    
    # Acknowledge the interrupt
    ldwio r5, 12(r9)   # Load the edge capture register to determine which button was pressed
    stwio r6, 12(r9)   # Clear the edge capture register to acknowledge the interrupt (by writing 0xF)
    
    # XOR the current value of RUN to toggle
    ldw r5, 0(r7)
    xori r5, r5, 0x1   # Toggle RUN value
    stw r5, 0(r7)      # Update RUN

    # Restore ra
     ldw ra, 0(sp)
     addi sp, sp, 4
    ret

TIMER_ISR:
    # Save ra
    subi sp, sp, 4
    stw ra, 0(sp)
	
	rdctl   r11, ctl0    # Disable interrupts
    wrctl   ctl0, r0
    
    # Acknowledge the interrupt
    movia r2, TIMER0_BASE
    movi r4, 0
    stwio r4, 0(r2)    # Clear TO bit

	# Load value of run
	ldw r5, 0(r7)

    # Load the value of count
    ldw r14, 0(r11)
	add r4, r14, r5 # Add whatever the value in run is to count
	stw r4, 0(r11) # Write the new value of count
	stwio r4, 0(r8)         # Update LEDs

    # Restore ra
    ldw ra, 0(sp)
    addi sp, sp, 4
	
	wrctl   ctl0, r11    # Re-enable interrupts
    ret

CONFIG_TIMER:
    # DEVICE SIDE
    movia r4, 0xff202000
    movia r5, 25000000
    stwio r0, 0(r4) # Clear TO
	movi r2, 0x8 # Stop it
    stwio r2, 4(r4) # Stop timer
	movi r2, 0x4 # Start it
    stwio r2, 4(r4) # Start timer
	stwio r5, 8(r4) # periodlo
    srli r5, r5, 16
    stwio r5, 12(r4) # periodhi
    stwio r0, 0(r4) # Clear TO
    movi r2, 0x7 # START | CONT | ITO
    stwio r2, 4(r4)
    # CPU SIDE
    rdctl r4, ctl3
    ori r4, r4, 1
    wrctl ctl3, r4 # Enable interrupts for IRQ0/timer
    wrctl ctl0, r4 # Enable interrupts globally
    ret

CONFIG_KEYS:
    movia r4, BUTTON_BASE       # Load base address of buttons into r4
    # Enable interrupts for all buttons
    movi r5, 0xF
    stwio r5, 8(r4)             # Write to interrupt mask register
    stwio r5, 12(r4)            # Clear any pending button interrupts
    # CTL3
    movi r5, 0x2                # Buttons are connected to IRQ1
    wrctl ctl3, r5              # Enable interrupts for IRQ1/buttons
    # CTL0
    movi r4, 0x1
    wrctl ctl0, r4              # Enable interrupts globally
    ret

IDLE: 
    br IDLE

.global COUNT
COUNT: .word 0x0

.global RUN
RUN: .word 0x1
.end
