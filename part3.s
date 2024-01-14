/*ECE243: Lab 1*/ 
/*part3.s V1*/ 
.global _start

/*Syntaxes (for reference)*/

/*Move constant to register*/
	# movia <destination>, <constant>
	
/*Add the content of two registers*/
	# add <destination>, <source1>, <source2>
	
/*Add the content of a register and a constant*/
	# addi <destination>, <source>, <constant>

/*Branch to label if greater than or equal*/
	#bge <src1>, <src2>, <label>
	
/*Jump to specified label no conditions*/
	#br <label>
	
/*Initialize Values*/
_start:
    movia   r8, 1      # Counter
    movia   r12, 0     # Sum
    movia   r9, 31     # Limit

loop:     
    bge     r8, r9, endloop  # if counter is >=31 exit loop which has no instructions
    add     r12, r12, r8     # add the counter to sum 
    addi    r8, r8, 1        # increment counter
    br      loop             # go to start

endloop:

inf_loop:
    br      inf_loop    #jump to itself forever (infinite loop)
