.text  # The numbers that turn into executable instructions
.global _start
_start:

/* r13 should contain the grade of the person with the student number, -1 if not found */
/* r10 has the student number being searched */


	movia r10, 10392584		# r10 is where you put the student number being searched for

/* Your code goes here  */

    movia r8, result   # the address of the result is in r8
    movia r11, Snumbers # the address of the student numbers is in r11
	movia r9, Grades # the address of the grades is in r9
    movia r12, 0       # index, initialize to 0
	movia r15, 0 		# offset, initialize to 0
    movia r13, -1      # default grade is -1 if not found

	ldw r14, (r11)      # load first student

loop:
    beq r14, r10, calculate  # if student number is found go to calculate grade
    beq r14, r0, finished  # if end of list send the default value
    addi r11, r11, 4    # add 4 to pointer to the numbers to point to next one
    addi r12, r12, 1    # increment index
    ldw  r14, (r11)    # load next student number
    br loop
	
calculate:
	# add offset and address of grades to find grade
	add r15, r12, r9
	ldb r13, (r15) # put the value of r15 in r13
	
finished: stb r13, (r8) # store the answer into result; change this to stb from stw for byte
	.equ LEDs, 0xFF200000
	movia r25, LEDs
	stwio r13, (r25)
iloop: br iloop


.data  	# the numbers that are the data 

/* result should hold the grade of the student number put into r10, or
-1 if the student number isn't found */ 

result: .byte 0
.align 2 #fix address alighment issue (fill 0s)
		
/* Snumbers is the "array," terminated by a zero of the student numbers  */
Snumbers: .word 10392584, 423195, 644370, 496059, 296800
        .word 265133, 68943, 718293, 315950, 785519
        .word 982966, 345018, 220809, 369328, 935042
        .word 467872, 887795, 681936, 0


/* Grades is the corresponding "array" with the grades, in the same order*/
Grades: .byte 99, 68, 90, 85, 91, 67, 80
        .byte 66, 95, 91, 91, 99, 76, 68  
        .byte 69, 93, 90, 72
