.global _start

.equ TIMER0_BASE, 0xFF202000    
.equ TIMER0_STATUS, 0           
.equ TIMER0_CONTROL, 4          
.equ TIMER0_PERIODL, 8         
.equ TIMER0_PERIODH, 12        
.equ TIMER0_SNAPL, 16           
.equ TIMER0_SNAPH, 20           

# the tick rate is 100 MHz, need 25000000 ticks for 0.25 seconds
.equ TICKS_FOR_025SEC, 25000000

_start:
    movia r8, 0xFF200000       # LEDs
    movia r9, 0xFF200050       # Buttons (active low)
    movia r10, 0xFF202000      # Timer base address
    movi r3, 255               # Maximum counter value
    movi r5, 1                 # Initial state 
    movi r4, 0                 # Counter start value

wait_start:
    ldwio r2, 12(r9)         # Load the Edge Capture register value
    beq r2, r0, wait_start # if no button press detected, keep waiting
    stwio r2, 12(r9)         # Clear the Edge Capture register
    movi r5, 0               # Change state to start counting

main:
    ldwio r2, 12(r9)         # Load the Edge Capture register value again
    bne r2, r0, toggle_state # If any bit is set, button was pressed
    beq r5, r0, update  # If counting state is active, update LEDs
    br main          

toggle_state:
    movi r6, 1
    xor r5, r5, r6          
    stwio r2, 12(r9)         # Reset Edge Capture register bits to acknowledge button press
    br main           

update:
    call TIMER_DELAY               
    addi r4, r4, 1           # Increment the counter
    bne r4, r3, continue    # If counter is not 255, skip reset
reset:
    movi r4, 0               # Reset counter to 0
continue:
    stwio r4, 0(r8)          # Update LEDs with the counter value
    br main		         

TIMER_DELAY:
    movia r10, TIMER0_BASE      # r10 the base address of the timer

    # Stop the timer first
    movi r11, 0x8               # Prepare the stop command for the control register
    stwio r11, TIMER0_CONTROL(r10) # Write to the control register to stop the timer
    movi r11, %lo(TICKS_FOR_025SEC) # Lower 16b of tick count
    stwio r11, TIMER0_PERIODL(r10)  # Write to period low reg
    movi r11, %hi(TICKS_FOR_025SEC) # Upper 16b of tick count
    stwio r11, TIMER0_PERIODH(r10)  # Write to period high reg

    # Start the timer
    movi r11, 0x4               # Prepare the start command for the control register
    stwio r11, TIMER0_CONTROL(r10) # Write to the control register to start the timer

    # Polling the TO bit in the Stats reg
poll_timer:
    ldwio r11, TIMER0_STATUS(r10) # Read the Status reg
    andi r11, r11, 0x1            # Get the TO bit
    beq r11, r0, poll_timer       # if TO bit is not set, keep polling

    movi r11, 0x1                 # Prepare the value to clear TO bit
    stwio r11, TIMER0_STATUS(r10) # clear TO bit
    ret                           
