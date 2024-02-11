.section .exceptions, "ax" #Interrupt Handler

     addi sp, sp, -8

     stw r2, 0(sp)

     stw r4, 4(sp)

    

     movia r2, 0xff200000

     ldwio r4, 0(r2)

     xori r4, r4, 0x8

     stwio r4, 0(r2)

    

     movia r2, 0xff200050

     movi r4, 1

     stwio r4, 12(r2) #clear edge for button 0

    

     ldw r4, 4(sp)

     ldw r2, 0(sp)

     addi sp, sp, 8

    

     addi ea, ea, -4

     eret

.text

.global _start

_start:

     movia sp, 0x200000

     call button0EnableInt

    

loop:

     br loop

 

button0EnableInt:

     movia r2, 0xff200050 #buttons

     movi r4, 0x1

     stwio r4, 12(r2) # reset EDGE bit

     stwio r4, 8(r2)

     movi r5, 0x2

     wrctl ctl3, r5 # enable ints for IRQ1/buttons

     wrctl ctl0, r4 # enable ints globally

     ret
