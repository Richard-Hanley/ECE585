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
   constant START_ADDR    : std_logic_vector(31 downto 0) := (others => '0');
   constant CYCLE_TIME    : time := 10 ns; -- Rate of 100 MHz
   constant BYTE_SIZE     : integer := 8; -- Size of a Byte
   constant PROG_FILENAME : string := "code.hex"; -- Name of code to run.
   constant NOCACHE       : std_logic := '1';
   
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
      constant SLL_FUNC : std_logic_vector(5 downto 0) := "000000";
      constant NOR_FUNC : std_logic_vector(5 downto 0) := "100111"; -- From http://www.cs.umd.edu/class/spring2003/cmsc311/Notes/Mips/bitwise.html
   constant BEQ_OP : std_logic_vector(31 downto 26) := "000100";
   constant J_OP   : std_logic_vector(31 downto 26) := "000010";
   
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
   constant BUS_CYCLE_TIME : time := CYCLE_TIME / BUS_BW;
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
   
   -- Metric Counters
   shared variable ICACHE_HITS : integer := 0;
   shared variable DCACHE_HITS : integer := 0;
   shared variable DBSET       : integer := 0;
   
   function log2(A : integer) return integer;
   function max4(A : integer;
                 B : integer;
                 C : integer;
                 D : integer) return integer;
                 
end constants;

package body constants is 

   function log2(A: integer) return integer is
   begin
      for I in 1 to 30 loop  -- Works for up to 32 bit integers
         if(2**I > A) then 
            return(I-1);  
         end if;
      end loop;
      report "constants.vhd: error could not determine log2 of integer)" severity FAILURE;
      return(-1);
   end function;
   
   function max4(A : integer;
                 B : integer;
                 C : integer;
                 D : integer) return integer is
   variable maxAB : integer;
   variable maxCD : integer;
   begin
      if A > B then
         maxAB := A;
      else 
         maxAB := B;
      end if;
      
      if C > D then
         maxCD := C;
      else
         maxCD := D;
      end if;
      
      if maxAB > maxCD then
         return maxAB;
      else
         return maxCD;
      end if;
   end function;
   
end package body;

