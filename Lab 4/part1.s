.global _start
_start:
    movia r8, 0xFF200000 # LEDs
    movia r9, 0xFF200050 # Buttons (active low)
    movia r10, 0x0 # Initialize previous state of buttons to all 0
	
	movia r6, 1 # Lower Limit for decrement
	movia r7, 15 # Upper limit for increment
    
polling:
    ldwio r2, 0(r9) # Read current value from buttons into r2
    xor r11, r2, r10 # XOR current and previous states to find changes
    and r11, r11, r10 # AND with previous state to find negative edges (0->1 transitions)
    
	# For each button: check negedge (when button is released to stop spam)
	
    # Check for negedge on Button 0
    andi r12, r11, 0x1 # Isolate button 0 change
    bne r12, r0, button0
    
    # Check for negedge on Button 1
    andi r12, r11, 0x2 # Isolate button 1 change
    bne r12, r0, button1
    
    # Check for negedge on Button 2
    andi r12, r11, 0x4 # Isolate button 2 change
    bne r12, r0, button2
    
    # Check for negedge on Button 3
    andi r12, r11, 0x8 # Isolate button 3 change
    bne r12, r0, button3
    
    # Update previous state
    mov r10, r2
    br polling

button0:
 	ldwio r4, 0(r8) # Read the status of the LEDs into r4
    movi r4, 1 		# Set to 1
    stwio r4, 0(r8) # Update LEDs
    br update_state

button1:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
	beq r4, r7, update_state # Skip increment if at limit already
    addi r4, r4, 1	# Add 1
    stwio r4, 0(r8) # Update LEDs
    br update_state

button2:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
	beq r4, r6, update_state # Skip decrement if at limit already
    subi r4, r4, 1	# Subtract 1
    stwio r4, 0(r8) # Update LEDs
    br update_state

button3:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
    movi r4, 0		# Set to 0
    stwio r4, 0(r8) # Update LEDs
    br update_state

update_state:
    mov r10, r2 # Update previous state with current state
    br polling
