IMM R1, 1
IMM R3, 100
IMM R4, 4
IMM R20, 300
IMM R19, 25
IMM R12, 12
LW R5, 0(R3) 
LW R6, 4(R3)
SLT R7, R5, R6
BEQ R7, R0, 2
ADD R7, R5, R6
J 14
AND R7, R5, R6
SW R7, 0(R20)
NOR R8, R5, R6
SW R8, 4(R20)
SLL R9, R5, 2
SLL R10, R6, 4
SW R9, 8(R20)
SW R10, 12(R20)
ADD R3, R4, R3
ADD R20, R12, R20
ADD R2, R1, R2
BNE R19, R2, -17
