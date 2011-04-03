----------------------------------------------------------------------------------
-- Engineer: Spenser Gilliland & Richard Hanley
-- License:  GPLv3
----------------------------------------------------------------------------------

-- This file defines constants used throughout the design.  It is "use"'d in each
-- source file.

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package constants is
   -- My Constants
   constant CYCLE_TIME    : time := 10 ns; -- Rate of 100 MHz
   constant BYTE_SIZE     : integer := 8; -- Size of a Byte
   constant PROG_FILENAME : string := "code.asm"; -- Name of code to run.
   
   -- From CPU Requirments
   constant CPU_WIDTH          : integer := 32; -- 32 bit MIPS CPU
   constant MEM_ADDRESSABILITY : integer := 8;  -- Byte addressable
   constant WORD_SIZE          : integer := 32; -- 32 bit words
   -- FIXME: Need to get info from Borkar on this.
   constant NUM_REGS           : integer := 32; -- 32 registers in the register file.
   
   -- MIPS32 ISA
   constant LW_OP  : std_logic_vector(31 downto 26) := "100011";
   constant SW_OP  : std_logic_vector(31 downto 26) := "101011";
   constant ALU_OP : std_logic_vector(31 downto 26) := "000000";
      constant ADD_FUNC : std_logic_vector(5 downto 0) := "100000";
      constant AND_FUNC : std_logic_vector(5 downto 0) := "100100";
      constant SLT_FUNC : std_logic_vector(5 downto 0) := "101010";
   constant BEQ_OP : std_logic_vector(31 downto 26) := "000100";
   constant J_OP   : std_logic_vector(31 downto 26) := "000100";
   
   -- Additional OPs based on ID Number A20254941
   constant BNE_OP : std_logic_vector(31 downto 26) := "000101";    -- found at http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html 
   constant LUI_OP : std_logic_vector(31 downto 26) := "001111";    -- found at http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html 
      constant JR_FUNC  : std_logic_vector(5 downto 0) := "001000"; -- found at http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html 
   
   -- From Bus Requirements
   constant BUS_BW : integer := 32;
   
   -- From Cache/Bus/Memory/Specifications
   constant ICACHE_SIZE : integer := 512 * BYTE_SIZE;
   constant DCACHE_SIZE : integer := 256 * BYTE_SIZE;
   constant BLOCK_SIZE  : integer := 4 * WORD_SIZE;
   constant CACHE_ACCESS_CYCLES : integer := 1;
   
   -- From Memory Requirements
   constant MEM_SIZE   : integer := 2048 * BYTE_SIZE;
   constant MEM_PORT_READ_CYCLES  : integer := 6;
   constant MEM_PORT_WRITE_CYCLES : integer := 4;
   constant MEM_ADD_READ_CYCLES   : integer := 2;
   constant MEM_ADD_WRITE_CYCLES  : integer := 3;
   
   -- Assumptions:
   -- The memory bus will run at 32x the speed of the processor to gain the needed bandwidth.
   constant BUS_CYLE_TIME : time := CYCLE_TIME / BUS_BW;
   -- Assuming 32 bit addressing (no PAE, etc) 
   constant ADDR_WIDTH  : integer := 32;
   -- Assuming a 32 bit data bus throughout. 
   constant BUS_WIDTH   : integer := 32;
   
   -- Infered attributes
   constant MEM_DEPTH    : integer := MEM_SIZE / MEM_ADDRESSABILITY;
   constant ICACHE_DEPTH : integer := ICACHE_SIZE / MEM_ADDRESSABILITY;
   constant DCACHE_DEPTH : integer := DCACHE_SIZE / MEM_ADDRESSABILITY;
   
   constant MEM_READ_TIME  : time := (MEM_PORT_READ_CYCLES + MEM_ADD_READ_CYCLES) * CYCLE_TIME;
   constant MEM_WRITE_TIME : time := (MEM_PORT_WRITE_CYCLES + MEM_ADD_WRITE_CYCLES) * CYCLE_TIME;
   constant CACHE_ACCESS_TIME : time := CACHE_ACCESS_CYCLES * CYCLE_TIME;
   
   -- Created some additional types for the various memory elements
   type mem_t     is array(MEM_DEPTH-1 downto 0)    of std_logic_vector(WORD_SIZE-1 downto 0); 
   type icache_t  is array(ICACHE_DEPTH-1 downto 0) of std_logic_vector(WORD_SIZE-1 downto 0);
   type dcache_t  is array(DCACHE_DEPTH-1 downto 0) of std_logic_vector(WORD_SIZE-1 downto 0);
   type regfile_t is array(NUM_REGS-1 downto 0)     of std_logic_vector(WORD_SIZE-1 downto 0);
   
   -- Metric Counters
   variable ICACHE_HITS : integer := 0;
   variable DCACHE_HITS : integer := 0;
   variable DBSET       : integer := 0;
   
end Constants;
