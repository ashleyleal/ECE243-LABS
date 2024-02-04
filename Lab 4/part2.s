.global _start
_start:
    movia r8, 0xFF200000 # LEDs
    movia r9, 0xFF200050 # Buttons (active low)
    movi r3, 255             # Maximum counter value
    movi r5, 1               # Initial state 
    movi r4, 0               # Counter start value

wait_start:
    ldwio r2, 12(r9)         # Load the Edge Capture register value
    beq r2, r0, wait_start # if no button press detected, keep waiting
    stwio r2, 12(r9)         # Clear the Edge Capture register
    movi r5, 0               # Change state to start counting

main:
    ldwio r2, 12(r9)         # Load the Edge Capture register value again
    bne r2, r0, toggle_state # If any bit is set, button was pressed
    beq r5, r0, update  # If counting state is active, update LEDs
    br main             # Loop continuously

toggle_state:
    movi r6, 1
    xor r5, r5, r6          
    stwio r2, 12(r9)         # Reset Edge Capture register bits to acknowledge button press
    br main             # Return to the main loop

update:
    call DELAY               
    addi r4, r4, 1           # Increment the counter
    bne r4, r3, continue    # If counter is not 255, skip reset
reset:
    movi r4, 0               # Reset counter to 0
continue:
    stwio r4, 0(r8)          # Update LEDs with the counter value
    br main		         	 # Continue the main loop

# Delay subroutine that waits 2.5s
DELAY:
    movia r11, 500000       # Delay counter for CPUlator, adjust for actual hardware
delay_loop:
    subi r11, r11, 1        # Decrement delay counter
    bne r11, r0, delay_loop # Loop until counter reaches 0
    ret                     # Return from delay
