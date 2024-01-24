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

#Subroutine that counts bits
ONES: 
    movi r2, 0            # store the value of the counter in r2
    movi r7, 32           # 32 bits to check (num of times to shift)

    # Loop to check each bit
    check:
        andi r8, r4, 1    # get LSB of r4 into r8
        beq r8, r0, skip # skip if LSB is not 1
        addi r2, r2, 1    # increment counter in r2

    skip:
    srai r4, r4, 1        # shift r4 right by 1 bit
    subi r7, r7, 1        # decrement num bits left to check
	bne r7, r0, check

    ret                  # return from subroutine


.text
.global _start

_start:
    movia r3, InputWord   # the address of InputWord is in r3
    ldw r4, 0(r3)         # the value of InputWord is in r4
    call ONES             # call ONES subroutine
    movia r5, Answer      # the value of Address is in r5
    stw r2, 0(r5)         # store result from r2 to Answer


endiloop: br endiloop

.data
InputWord: .word 0x4a01fead
Answer: .word 0
