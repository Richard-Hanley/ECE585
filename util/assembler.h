/*
 * compiler.h
 *
 *  Created on: Nov 8, 2010
 *      Author: spenser
 */

#ifndef COMPILER_H_
#define COMPILER_H_

#define MAX_LINE_LENGTH 80

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Start of Constants */
#define LW_OP  0x23
#define SW_OP  0x2B
#define ALU_OP 0x00
#define BEQ_OP 0x04
#define J_OP   0x08
#define BNE_OP 0x05
#define LUI_OP 0x0F
#  define ADD_FUNC 0x20
#  define AND_FUNC 0x24
#  define SLT_FUNC 0x2C
#  define JR_FUNC  0x08

#define OPMASK 0xFC000000
#define RSMASK 0x03E00000
#define RTMASK 0x001F0000
#define RDMASK 0x0000F800
#define STMASK 0x000007C0
#define FUMASK 0x0000003F
#define IMMASK 0x0000FFFF
#define ADMASK 0x03FFFFFF

#define OPSTART 26
#define RSSTART 21
#define RTSTART 16
#define RDSTART 11
#define STSTART 6
#define FUSTART 0
#define IMSTART 0
#define ADSTART 0

unsigned int assemble(char* line);

#endif /* COMPILER_H_ */
