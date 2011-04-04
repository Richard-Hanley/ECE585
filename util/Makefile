#
#
#

BIN=assembler

assembler-SRC=assembler.c

assembler-OBJ=assembler.o

assembler-INC=assembler.h

assembler-LIB=


.PHONY: all clean install

all: $(BIN)

clean: 
	rm -rf $(BIN) $(assembler-OBJ) ece585_binutils.tar.gz
	
install: assembler
	cp assembler /usr/local/bin/mips32-assembler

assembler: $(assembler-OBJ) 
	@echo 'Building target: $@'
	@echo 'Invoking: GCC C Linker'
	gcc  -o "$@" $(assembler-OBJ) $(assembler-LIB)
	@echo 'Finished building target: $@'
	@echo ' '

ece585_binutils.tar.gz: $(assembler-SRC) $(disassembler-SRC)
	@echo 'Building release: $@'
	@echo 'Invoking: Tar archiver'
	tar cvf ece585_binutils.tar.gz $(assembler-SRC) $(assembler-INC) Makefile
	@echo 'Finished building target: $@'
	@echo ' '

%.o: %.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc -O0 -g3 -Wall -c "$<"
	@echo 'Finished building: $<'
	@echo ' '
