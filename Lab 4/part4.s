.global _start

.equ TIMER0_BASE, 0xFF202000    
.equ TIMER0_STATUS, 0           
.equ TIMER0_CONTROL, 4          
.equ TIMER0_PERIODL, 8         
.equ TIMER0_PERIODH, 12        
.equ TIMER0_SNAPL, 16           
.equ TIMER0_SNAPH, 20           

# The tick rate is 100 MHz, need 1,000,000 ticks for 0.01 seconds
.equ TICKS_FOR_001SEC, 1000000

.equ LED_BASE, 0xFF200000       # LEDs base address
.equ BUTTON_BASE, 0xFF200050    # Buttons base address

.equ MAX_SECONDS, 8            # Maximum seconds before wrap-around
.equ MAX_HUNDREDTHS, 99         # Maximum hundredths of a second before incrementing seconds

_start:
    movia r8, LED_BASE          # LEDs
    movia r9, BUTTON_BASE       # Buttons (active low)
    movia r10, TIMER0_BASE      # Timer base address
    movi r11, 0                 # Counter for hundredths of a second
    movi r12, 0                 # Counter for seconds
    movi r13, 1                 # state (1: paused, 0:running)
	movi r4, MAX_SECONDS		# store max seconds in r4
	movi r5, MAX_HUNDREDTHS		# store maxc hundredths in r5

init_timer:
    movi r14, 0x8               # Stop the timer
    stwio r14, TIMER0_CONTROL(r10)
    movi r14, %lo(TICKS_FOR_001SEC)
    stwio r14, TIMER0_PERIODL(r10)
    movi r14, %hi(TICKS_FOR_001SEC)
    stwio r14, TIMER0_PERIODH(r10)


main:
    ldwio r14, 12(r9)           # Read the button press status
    bne r14, r0, toggle_clock   # If any button pressed, toggle clock state
    beq r13, r0, update   # If clock is running, update display
    br main

toggle_clock:
    xori r13, r13, 0x1          # Toggle clock state
    stwio r14, 12(r9)           # Clear the Edge Capture register
    br main

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
    br main

timer_delay:
    movi r14, 0x4               # Start timer command
    stwio r14, TIMER0_CONTROL(r10)
poll_timer:
    ldwio r14, TIMER0_STATUS(r10)
    andi r14, r14, 0x1
    beq r14, r0, poll_timer     # if TO bit is not set, keep polling
    movi r14, 0x1
    stwio r14, TIMER0_STATUS(r10) # Clear TO bit
    ret 
