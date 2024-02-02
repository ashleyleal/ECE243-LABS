.global _start
_start:
    
    movia r8, 0xFF200000 # LEDs
    movia r9, 0xFF200050 # Buttons (active low)
    
polling:
    ldwio r2, 0(r9) # Read value from buttons into r2
    
    andi r3, r2, 0x1 # Extract the bit representing Push button 0
    bne r3, r0, key0 # If button 0 is pressed, toggle LED 0
    
    andi r3, r2, 0x2 # Extract the bit representing Push button 1
    bne r3, r0, key1 # If button 1 is pressed, toggle LED 1
    
    andi r3, r2, 0x4 # Extract the bit representing Push button 2
    bne r3, r0, key2 # If button 2 is pressed, toggle LED 2
    
    andi r3, r2, 0x8 # Extract the bit representing Push button 3
    bne r3, r0, key3 # If button 3 is pressed, toggle LED 3
    
    br polling # Loop back to start if no button is pressed
    
key0:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
    xori r4, r4, 0x1 # Toggle LED 0
    stwio r4, 0(r8) # Update LEDs
    br polling
    
key1:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
    xori r4, r4, 0x2 # Toggle LED 1
    stwio r4, 0(r8) # Update LEDs
    br polling
    
key2:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
    xori r4, r4, 0x4 # Toggle LED 2
    stwio r4, 0(r8) # Update LEDs
    br polling
    
key3:
    ldwio r4, 0(r8) # Read the status of the LEDs into r4
    xori r4, r4, 0x8 # Toggle LED 3
    stwio r4, 0(r8) # Update LEDs
    br polling
