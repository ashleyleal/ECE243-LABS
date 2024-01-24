.text
/* Program to Count the number of 1’s in a 32-bit word,
located at InputWord */
# used Lecture 7: Bitwise operations shift

/*
Idea:
- Shift bits as many times as the number of bits (32b)
- Each iteration check if LSB is 1
	- If it is, increment counter and continue
	- Otherwise continue with next iteration
*/
.global _start
_start:
    movia r3, InputWord   # the address of InputWord is in r3
    ldw r4, 0(r3)         # the value of InputWord is in r4
    movia r5, Answer      # the value of Address is in r5
    movi r6, 0            # store the value of the counter in r6
    movi r7, 32           # 32 bits to check (num of times to shift)

check:
    andi r8, r4, 1        # get LSB of r4 into r8
    beq r8, zero, skip # skip if not 1
    addi r6, r6, 1        # 1 found, increment counter

skip:
    srai r4, r4, 1        # shift r4 right by 1 bit
    subi r7, r7, 1        # decrement num bits left to check
	bne r7, r0, check
	br finished

finished:
    stw r6, 0(r5)    #store counter value into the address in register r5 with an offset of 0 
    br endiloop         

endiloop: br endiloop


.data
InputWord: .word 0x4a01fead
Answer: .word 0
