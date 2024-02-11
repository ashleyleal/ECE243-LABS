.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
.equ BUTTONS_BASE, 0xff200050
.equ STACK_ADD, 0x200000
/******************************************************************************
 * Write an interrupt service routine
 *****************************************************************************/
.section .exceptions, "ax"
IRQ_HANDLER:
        # Save registers on the stack
        subi    sp, sp, 28          # Make room on the stack for et, ra, r20, r3, r4, r5, ea
        stw     et, 0(sp)
        stw     ra, 4(sp)
        stw     r20, 8(sp)
        stw     r3, 12(sp)         # Save r3
        stw     r4, 16(sp)         # Save r4
        stw     r5, 20(sp)         # Save r5

        rdctl   et, ctl4            # Read exception type
        beq     et, r0, SKIP_EA_DEC # Not external?
        subi    ea, ea, 4           # Decrement ea by 4 for external interrupts

SKIP_EA_DEC:
        stw     ea, 24(sp)          # Save ea
        andi    r20, et, 0x2        # Check if interrupt is from pushbuttons
        beq     r20, r0, END_ISR    # If not, ignore this interrupt
        call    KEY_ISR             # If yes, call the pushbutton ISR

END_ISR:
        ldw     et, 0(sp)           # Restore registers
        ldw     ra, 4(sp)
        ldw     r20, 8(sp)
        ldw     r3, 12(sp)          # Restore r3
        ldw     r4, 16(sp)          # Restore r4
        ldw     r5, 20(sp)          # Restore r5
        ldw     ea, 24(sp)
        addi    sp, sp, 28          # Restore stack pointer
        eret                        # Return from exception
                     # return from exception

/*********************************************************************************
 * set where to go upon reset
 ********************************************************************************/
.section .reset, "ax"
        movia   r8, _start
        jmp    r8

/*********************************************************************************
 * Main program
 ********************************************************************************/
.text
.global  _start
_start:
        /*
        1. Initialize the stack pointer
        2. set up keys to generate interrupts
        3. enable interrupts in NIOS II
        */
		
	movia sp, STACK_ADD # Initialize the stack pointer
	movia r7, BUTTONS_BASE
	movia r9, 1
	call enable_button_interrupts
	br IDLE
	
KEY_ISR: # Control the HEX displays here, can move to different file in Monitor Program
	#SAVE ra TO PREVENT CLOBBERED REGISTER
	subi    sp, sp, 4
    stw     ra, 0(sp)

	movia   r4, BUTTONS_BASE      # Load base address of BUTTONS into r4
    ldwio   r5, 12(r4)  # Load the edge capture register to determine which button was pressed
    stwio   r9, 12(r4)  # Clear the edge capture register to acknowledge the interrupt

    # Check for KEY0
    andi    r6, r5, 0x1
    bne     r6, r0, TOGGLE_HEX0
	
    # Check for KEY1
    andi    r6, r5, 0x2
    bne     r6, r0, TOGGLE_HEX1
    # Check for KEY2
    andi    r6, r5, 0x4
    bne     r6, r0, TOGGLE_HEX2
    # Check for KEY3
    andi    r6, r5, 0x8
    bne     r6, r0, TOGGLE_HEX3
	
    # Restore the ra register
    ldw     ra, 0(sp)
    addi    sp, sp, 4
	
    # Finish the ISR
    ret

TOGGLE_HEX0:
	
	ldwio   r6, 0(r7)		  # Read the current
    xori    r6, r6, 0x00      		# Toggle the state
    mov   	r4, r6
    movia 	r5, 0x00		
    call HEX_DISP
	
	ret #CLOBBERED REGISTERS sp ra HAPPENS HERE
	
TOGGLE_HEX1:
	
	ldwio   r6, 0(r7)		  # Read the current
    xori    r6, r6, 0x10      		# Toggle the state
    mov   	r4, r6
    movia 	r5, 0x01		
    call HEX_DISP

	ret #CLOBBERED REGISTERS sp ra HAPPENS HERE
	
TOGGLE_HEX2:
	
	ldwio   r6, 0(r7)		  # Read the current
    xori    r6, r6, 0x20      		# Toggle the state
    mov   	r4, r6
    movia 	r5, 0x02		
    call HEX_DISP

	ret #CLOBBERED REGISTERS sp ra HAPPENS HERE

TOGGLE_HEX3:
	
	ldwio   r6, 0(r7)		  # Read the current
    xori    r6, r6, 0x30      		# Toggle the state
    mov   	r4, r6
    movia 	r5, 0x03		
    call HEX_DISP


	ret #CLOBBERED REGISTERS sp ra HAPPENS HERE

enable_button_interrupts:
	
    movia   r4, BUTTONS_BASE       # Load base address of buttons into r4
    
	# Enable interrupts for all buttons by setting their corresponding bits in the interrupt mask register
    movi    r5, 0xF         # we have 4 buttons and want to enable interrupts for all
    stwio   r5, 8(r4)       # Write to interrupt mask register at offset
	
	# clear any pending button interrupts by writing to the edge capture register
    stwio   r5, 12(r4)   # Write to edge capture register at offset to clear it

      # CPU SIDE
      
	  #CTL3
      movi r5, 0x2   # button are connected to IRQ1 (2nd bit of ctl3)
      wrctl ctl3, r5 # enable ints for IRQ1/buttons

      #CTL0
      movi r4, 0x1
      wrctl ctl0, r4 # enable ints globally (bit 0)
	  ret

IDLE:   br  IDLE

HEX_DISP:   movia    r8, BIT_CODES         # starting address of the bit codes
	    andi     r6, r4, 0x10	   # get bit 4 of the input into r6
	    beq      r6, r0, not_blank 
	    mov      r2, r0
	    br       DO_DISP
not_blank:  andi     r4, r4, 0x0f	   # r4 is only 4-bit
            add      r4, r4, r8            # add the offset to the bit codes
            ldb      r2, 0(r4)             # index into the bit codes

#Display it on the target HEX display
DO_DISP:    
			movia    r8, HEX_BASE1         # load address
			movi     r6,  4
			blt      r5,r6, FIRST_SET      # hex4 and hex 5 are on 0xff200030
			sub      r5, r5, r6            # if hex4 or hex5, we need to adjust the shift
			addi     r8, r8, 0x0010        # we also need to adjust the address
FIRST_SET:
			slli     r5, r5, 3             # hex*8 shift is needed
			addi     r7, r0, 0xff          # create bit mask so other values are not corrupted
			sll      r7, r7, r5 
			addi     r4, r0, -1
			xor      r7, r7, r4  
    		sll      r4, r2, r5            # shift the hex code we want to write
			ldwio    r5, 0(r8)             # read current value       
			and      r5, r5, r7            # and it with the mask to clear the target hex
			or       r5, r5, r4	           # or with the hex code
			stwio    r5, 0(r8)		       # store back
END:			
			ret
			
BIT_CODES:  .byte     0b00111111, 0b00000110, 0b01011011, 0b01001111
			.byte     0b01100110, 0b01101101, 0b01111101, 0b00000111
			.byte     0b01111111, 0b01100111, 0b01110111, 0b01111100
			.byte     0b00111001, 0b01011110, 0b01111001, 0b01110001

            .end
