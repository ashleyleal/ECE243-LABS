.global _start
_start:
	
	movia r8, 0xFF200000 #LEDs
	movia r9, 0xFF200050 # Buttons
	
fever:
	ldwio r2, 12(r9) # Buttons edge
	andi r2, r2, 0x4 # Extract the bit representing Push button 2
	beq r2, r0, nexttime # If button two is not the button being pressed, keep polling
	
yes:
	ldwio r4, 0(r8) # Read the status of the LEDs into r4
	xori r4, r4, 0x1 # Flip the bits to switch on 
	stwio r4, 0(r8) # Toggle LED
	stwio r2, 12(r9) # Reset the edge
	
nexttime: 
	br fever
