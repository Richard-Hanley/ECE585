IMM R3, 200 #the memormy address for the input data
IMM R22, 240 #location of canned data
IMM R20, 320 #write-pad for output
IMM R19, 5 #number of iterations
IMM R1, 1 #constant value for adding to loop counter
IMM R2, 0 #loop counter
IMM R4, 8 #memory add for input stream
IMM R16, 16 #memory add for output stream
IMM R17, 10 #The number of instructions so far
ADD R25, R17, R25 #Keep a count of the number of instructions
LW R5, 0(R3) #Get your input data
LW R6, 4(R3)
SLT R7, R5, R6 #branch if R5<R6
BEQ R7, R0, 2 
ADD R7, R5, R6
J 17 #You are done here, go to the store
AND R7, R5, R6
SW R7, 0(R20)
LW R12, 0(R22) #load in the canned data
BNE R7, R12, 21 #if not correct, it's BAD
NOR R8, R5, R6
SW R8, 4(R20)
LW R12, 4(R22)
BNE R8, R12, 17
SLL R9, R5, 2
SLL R10, R6, 4
SW R9, 8(R20)
LW R12, 8(R22)
BNE R9, R12, 12
SW R10, 12(R20)
LW R12, 12(R22)
BNE R10, R12, 9
ADD R3, R4, R3 #New elem 
ADD R22, R16, R22 
ADD R20, R16, R20
ADD R2, R1, R2 #add to loop counter
IMM R17, 29 #the number of instructions in a loop 
ADD R55, R17, R25  #add the number to the instruction count
BNE R19, R2, -29 #check to see if you are done
LUI R28, 64 #store a bit to say that you finished correctly
IMM R23, 512 #prepare for the jump
STATS R24, R26, R27 #First, put the stats that are currently in the cpu
IMM R17, 5 #these last piece of instructions
ADD R25, R17, R25  #the count is completed
JR R23 #hurry jump before we die
BAD 0 #Oh shit, we're going to die
