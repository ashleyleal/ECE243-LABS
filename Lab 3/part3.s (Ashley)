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

/*
Registers

r4: stores input word value

ONES Subroutine:
r2: counter 
r7: reference for number of bits left to shift
r8: holds LSB of input word

MAIN:
r3: pointer to TEST_NUMs

r5: address of LargestOnes
r6: address of LargestZeroes

*/

.text
.global _start

_start:
    movia r3, TEST_NUM  # the address of TEST_NUM is in r3
	movia r5, LargestOnes # the address of LargestOnes is in r5
	movia r6, LargestZeroes # the address of LargestZeroes is in r6

	loop:
		# for each word:
		ldw r4, 0(r3)         # update the value of input word
		beq r4, r0, finished # check if at end of list
				
		determine_ones:
		call ONES             # call ONES subroutine
		ldw r9, 0(r5)  # load current largest ones count
		blt r2, r9, determine_zeroes  # if current count is less, skip updating LargestOnes and proceed to determine zeroes
		stw r2, 0(r5)  # update LargestOnes

		determine_zeroes:
		xori r4, r4, 0x10 # flip all the bits to count the zeroes (which get switched to ones to use ONES subroutine)
		call ONES             # call ONES subroutine
		ldw r9, 0(r6)  # load current largest zeroes count
		blt r2, r9, next_iteration  # if current count is less, skip updating LargesetZeroes and proceed to next iteration
		stw r2, 0(r5)  # update LargestZeroes
	
		next_iteration:
		addi r3, r3,4 # add 4 to point to next word
		br loop # if not at end of list, loop again
		
	finished:
		stw r10, 0(r5)
		stw r11, 0(r6)
		br endiloop
		
endiloop: br endiloop

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

.data
TEST_NUM: .word 0x4a01fead, 0xF677D671,0xDC9758D5,0xEBBD45D2,0x8059519D
.word 0x76D8F0D2, 0xB98C9BB5, 0xD7EC3A9E, 0xD9BADC01, 0x89B377CD
.word 0 # end of list
LargestOnes: .word 0
LargestZeroes: .word 0
