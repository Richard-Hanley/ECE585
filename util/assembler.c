/* File:    assmebler.c
 * Author:  Spenser Gilliland
 * License: GPLv3
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "assembler.h"

unsigned int assemble(char* line)
{
	char opcode[6];
	unsigned int d, t, s, imm, sh, addr, h;
   unsigned int assembly;
   
	/* Find the opcode */
	if(sscanf(line, "%s", opcode) != 1)
	{
		perror("Bad code\n");
		exit(EXIT_FAILURE);
	}

	/* Based on the opcode determine the values */
	if(strcmp(opcode, "LW") == 0)
	{
		if(sscanf(line, "LW R%i, %i(R%i]);", &t, &imm, &s) != 3)
		{
			perror("Bad LW");
			exit(EXIT_FAILURE);
		}
      assembly = ((LW_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((imm << IMSTART) & IMMASK);
	}
	else if(strcmp(opcode, "SW") == 0)
	{
		if(sscanf(line, "SW R%i, %i(R%i]);", &t, &imm, &s) != 3)
		{
			perror("Bad SW");
			exit(EXIT_FAILURE);
		}
      assembly = ((SW_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((imm << IMSTART) & IMMASK);
	}
   else if(strcmp(opcode, "STATS") == 0)
   {
      if(sscanf(line, "STATS R%i, R%i, R%i;", &d, &s, &t) != 3)
      {
         perror("Bad STATS");
         exit(EXIT_FAILURE);
      }
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) |
                 (( t << RTSTART) & RTMASK) | ((d << RDSTART) & RDMASK) | 
                 ((STATS_FUNC << FUSTART) & FUMASK);
   }
   else if(strcmp(opcode, "ADD") == 0 )
	{
		if(sscanf(line, "ADD R%i, R%i, R%i;", &d, &s, &t) != 3)
		{
			perror("Bad ADD");
			exit(EXIT_FAILURE);
		}
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((d << RDSTART) & RDMASK) | 
                 ((ADD_FUNC << FUSTART) & FUMASK);
	}
	else if(strcmp(opcode, "AND") == 0)
	{
		if(sscanf(line, "AND R%i, R%i, R%i;", &d, &s, &t) != 3)
		{
			perror("Bad AND");
			exit(EXIT_FAILURE);
		}
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((d << RDSTART) & RDMASK) | 
                 ((AND_FUNC << FUSTART) & FUMASK);
	}
	else if(strcmp(opcode, "SLL") == 0)
	{
		if(sscanf(line, "SLL R%i, R%i, %i;", &d, &t, &h) != 3)
		{
			perror("Bad SLL");
			exit(EXIT_FAILURE);
		}
        s = 0;//it is a somewhat odd instruction 
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((d << RDSTART) & RDMASK) | 
                 ((h << HSTART) & HMASK) | ((SLL_FUNC << FUSTART) & FUMASK);
	}
	else if(strcmp(opcode, "JR") == 0)
	{
		if(sscanf(line, "JR R%i;", &s) != 1)
		{
			perror("Bad JR");
			exit(EXIT_FAILURE);
		}
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) |
                 ((JR_FUNC << FUSTART) & FUMASK);
	}
	else if(strcmp(opcode, "BEQ") == 0)
	{
		if(sscanf(line, "BEQ R%i, R%i, %i;", &s, &t, &imm) != 3)
		{
			perror("Bad BEQ");
			exit(EXIT_FAILURE);
		}
      assembly = ((BEQ_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((imm << IMSTART) & IMMASK);
	}
	else if(strcmp(opcode, "J") == 0)
	{
		if(sscanf(line, "J %i;", &addr) != 1)
		{
			perror("Bad J");
			exit(EXIT_FAILURE);
		}
      assembly = ((J_OP << OPSTART) & OPMASK) | ((addr << ADSTART) & ADMASK);
	}
	else if(strcmp(opcode, "BNE") == 0)
	{
		if(sscanf(line, "BNE R%i, R%i, %i;", &s, &t, &imm) != 3)
		{
			perror("Bad BNE");
			exit(EXIT_FAILURE);
		}
      assembly = ((BNE_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((imm << IMSTART) & IMMASK);
	}
	else if(strcmp(opcode, "LUI") == 0)
	{
	   if(sscanf(line, "LUI R%i, %i;", &t, &imm) != 2)
		{
			perror("Bad LUI");
			exit(EXIT_FAILURE);
		}
		assembly = ((LUI_OP << OPSTART) & OPMASK) | ((t << RTSTART) & RTMASK) | 
		           ((imm << IMSTART) & IMMASK);
	}
	else if(strcmp(opcode, "IMM") == 0)
	{
	   if(sscanf(line, "IMM R%i, %i;", &t, &imm) != 2)
		{
			perror("Bad IMM");
			exit(EXIT_FAILURE);
		}
		assembly = ((IMM_OP << OPSTART) & OPMASK) | ((t << RTSTART) & RTMASK) | 
		           ((imm << IMSTART) & IMMASK);
	}
	else if(strcmp(opcode, "NOR") == 0 )
	{
		if(sscanf(line, "NOR R%i, R%i, R%i;", &d, &s, &t) != 3)
		{
			perror("Bad NOR");
			exit(EXIT_FAILURE);
		}
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((d << RDSTART) & RDMASK) | 
                 ((NOR_FUNC << FUSTART) & FUMASK);
	}
	else if(strcmp(opcode, "SLT") == 0 )
	{
		if(sscanf(line, "SLT R%i, R%i, R%i;", &d, &s, &t) != 3)
		{
			perror("Bad SLT");
			exit(EXIT_FAILURE);
		}
      assembly = ((ALU_OP << OPSTART) & OPMASK) | ((s << RSSTART) & RSMASK) | 
                 ((t << RTSTART) & RTMASK) | ((d << RDSTART) & RDMASK) | 
                 ((SLT_FUNC << FUSTART) & FUMASK);
	}
    else if(strcmp(opcode, "BAD") == 0)
    {
        if(sscanf(line, "BAD %i", &imm) != 1)
        {
            perror("Bad BAD");
            exit(EXIT_FAILURE);
        }
        assembly = ((BAD_OP << OPSTART) & OPMASK | ((imm << IMSTART) & IMMASK));

    }

    else
	{
		perror("Bad OP");
		exit(EXIT_FAILURE);
	}
	return assembly;
}

int main(int argc, char* argv[])
{
	FILE *code;
	char* line = malloc(sizeof(char)*MAX_LINE_LENGTH);
	unsigned int output;

	if(argc != 2)
	{
		printf("usage: %s <filename>\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	code = fopen(argv[1], "r");

	while( fgets(line, MAX_LINE_LENGTH, code) != NULL)
	{
		output = assemble(line);
		printf("%08x\n", output);
	}

	return EXIT_SUCCESS;
}
