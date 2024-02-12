.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
.equ BUTTONS_BASE, 0xff200050
.equ STACK_ADD, 0x200000

/******************************************************************************
 * Write an interrupt service routine (ISR)
 *****************************************************************************/
.section .exceptions, "ax"
IRQ_HANDLER:
        # Save registers on the stack
        subi    sp, sp, 44          # Adjust stack pointer for saved registers to 44 bytes
        stw     et, 0(sp)           # Save exception temporary register
        stw     ra, 4(sp)           # Save return address
        stw     r20, 8(sp)          # Save general-purpose register
        stw     r3, 12(sp)          # Save general-purpose register
        stw     r4, 16(sp)          # Save general-purpose register
        stw     r5, 20(sp)          # Save general-purpose register
        stw     r6, 24(sp)          # Save r6 to the stack
        stw     r7, 28(sp)          # Save r7 to the stack
        stw     r2, 32(sp)          # Save r2 to the stack
        stw     r8, 36(sp)          # Save r8 to the stack
        # Exception handling
        rdctl   et, ctl4            # Read exception type
        beq     et, r0, SKIP_EA_DEC # Check if not external interrupt
        subi    ea, ea, 4           # Adjust exception address for external interrupts
SKIP_EA_DEC:
        stw     ea, 40(sp)          # Save exception address
        andi    r20, et, 0x2        # Check if interrupt is from pushbuttons
        beq     r20, r0, END_ISR    # If not, skip to end
        call    KEY_ISR             # Handle pushbutton interrupt
END_ISR:
        # Restore registers
        ldw     et, 0(sp)
        ldw     ra, 4(sp)
        ldw     r20, 8(sp)
        ldw     r3, 12(sp)
        ldw     r4, 16(sp)
        ldw     r5, 20(sp)
        ldw     r6, 24(sp)
        ldw     r7, 28(sp)
        ldw     r2, 32(sp)         # Restore r2 from the stack
        ldw     r8, 36(sp)         # Restore r8 from the stack
        ldw     ea, 40(sp)
        addi    sp, sp, 44         # Restore stack pointer
        eret                        # Return from exception
/*********************************************************************************
 * Set where to go upon reset
 ********************************************************************************/
.section .reset, "ax"
        movia   r8, _start
        jmp     r8

/*********************************************************************************
 * Main program
 ********************************************************************************/
.text
.global  _start
_start:
        # Initialize stack and set up for interrupts
        movia   sp, STACK_ADD          # Initialize the stack pointer
        movia   r4, BUTTONS_BASE
        movia   r7, HEX_BASE1
        movia   r9, 0xF
        call    enable_button_interrupts
        br      IDLE
	
KEY_ISR: # Control the HEX displays here, can move to different file in Monitor Program

	br SAVE

	TOGGLE_HEX0:
    	movia   r4, 0x0
    	movia 	r5, 0x00		
    	call HEX_DISP
		br RESTORE

	TOGGLE_HEX1:
    	movia   r4, 0x1
    	movia 	r5, 0x01		
    	call HEX_DISP
		br RESTORE

	TOGGLE_HEX2:
    	movia   r4, 0x2
    	movia 	r5, 0x02		
    	call HEX_DISP
		br RESTORE
	
	TOGGLE_HEX3:
    	movia   r4, 0x3
    	movia 	r5, 0x03		
    	call HEX_DISP
		br RESTORE

	SAVE:
		subi sp, sp, 4
		stw ra, 0(sp)

	LOAD:
		movia   r4, BUTTONS_BASE      # Load base address of BUTTONS into r4
    	ldwio   r5, 12(r4)  # Load the edge capture register to determine which button was pressed
    	stwio   r9, 12(r4)  # Clear the edge capture register to acknowledge the interrupt
	
    CHECK_KEY0:
    	andi    r6, r5, 0x1
    	bne     r6, r0, TOGGLE_HEX0
	
    CHECK_KEY1:
    	andi    r6, r5, 0x2
		bne     r6, r0, TOGGLE_HEX1

    CHECK_KEY2:
    	andi    r6, r5, 0x4
		bne     r6, r0, TOGGLE_HEX2

    CHECK_KEY3:
    	andi    r6, r5, 0x8
    	bne     r6, r0, TOGGLE_HEX3

	RESTORE:
		ldw ra, 0(sp)
		addi sp, sp, 4
	
	ret

enable_button_interrupts:
	
    movia   r4, BUTTONS_BASE       # Load base address of buttons into r4
    
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
