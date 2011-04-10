-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
--
-- Description: A MIPS32 emulator.
-- 
-- Theory of Operation:
--    This is a non-synthesizable MIPS32 emulator.
--    It simply performs the operation according to the
--    instruction in a total of 2 cycles (plus memory 
--    access times.)  The first cycle is used to 
--    increment the program counter the second performs 
--    the operation.
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;

entity cpu is
   Port (
      clk   : in    std_logic;
      reset : in    std_logic;
      
      -- Interface to Cache
      data  : inout std_logic_vector(BUS_WIDTH-1  downto 0);
      addr  : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
      wr    : out   std_logic;
      done  : in    std_logic;
      instr : out   std_logic
   );
end cpu;

architecture Behavioral of cpu is
   type regfile_t is array(NUM_REGS-1 downto 0) of std_logic_vector(WORD_SIZE-1 downto 0);
   
   function clear_regs return regfile_t is
      variable regfile : regfile_t;
   begin
      for I in NUM_REGS-1 downto 0 loop
         regfile(I) := (others => '0');
      end loop;
      return regfile;
   end function;
   
   signal regs : regfile_t := clear_regs;
   
   signal PC : std_logic_vector(ADDR_WIDTH-1 downto 0) := START_ADDR;
   signal IR : std_logic_vector(BUS_WIDTH-1 downto 0);
   
   alias OPCODE  : std_logic_vector(31 downto 26) is IR(31 downto 26);
   alias RS      : std_logic_vector(25 downto 21) is IR(25 downto 21);
   alias RT      : std_logic_vector(20 downto 16) is IR(20 downto 16);
   alias RD      : std_logic_vector(15 downto 11) is IR(15 downto 11);
   alias SHAMT   : std_logic_vector(10 downto 6)  is IR(10 downto 6);
   alias FUNC    : std_logic_vector(5  downto 0)  is IR(5 downto 0);
   alias IMM     : std_logic_vector(15 downto 0)  is IR(15 downto 0);
   alias ADDRESS : std_logic_vector(25 downto 0)  is IR(25 downto 0);
   
begin

   INSTR_EXEC: process 
   begin
      data := (others => 'Z');
      wr := '0';
      addr := PC;
      wait for CYCLE_TIME;
      wait until done = '1';
      IR := data;
      wait for CYCLE_TIME;
      if    OPCODE = LW_OP then
         addr := regs(conv_integer(RS)) + IMM; 
         wait for CYCLE_TIME; -- Give the done signal time to be reset.
         wait until done = '1';
         regs(conv_integer(RT)) := data;
         report "Completed LW R" & integer'image(conv_integer(RT)) & " " & integer'image(conv_integer(IMM)) & "(R" & integer'image(conv_integer(RS)) & ")" severity NOTE;
      elsif OPCODE = SW_OP then
         wr := '1';
         addr := IMM + regs(conv_integer(RS));
         data := regs(conv_integer(RT));
         wait for CYCLE_TIME; -- Give the done signal time to be reset
         wait until done = '1';
         report "Completed SW R" & integer'image(conv_integer(RT)) & " " & integer'image(conv_integer(IMM)) & "(R" & integer'image(conv_integer(RS)) & ")" severity NOTE;
      elsif OPCODE = ALU_OP then
         if    FUNC = ADD_FUNC then
            regs(conv_integer(RD)) := regs(conv_integer(RS)) + regs(conv_integer(RT));
            report "Completed ADD R" & integer'image(conv_integer(RD)) & " R" & integer'image(conv_integer(RS)) & " R" & integer'image(conv_integer(RT)) severity NOTE;
         elsif FUNC = AND_FUNC then
            regs(conv_integer(RD)) := regs(conv_integer(RS)) and regs(conv_integer(RT));
            report "Completed AND R" & integer'image(conv_integer(RD)) & " R" & integer'image(conv_integer(RS)) & " R" & integer'image(conv_integer(RT)) severity NOTE;
         elsif FUNC = SLT_FUNC then
            if regs(conv_integer(RS)) < regs(conv_integer(RT)) then   
               regs(conv_integer(RD)) := conv_std_logic_vector(1, BUS_WIDTH);
            else
               regs(conv_integer(RD)) := (others => '0');
            end if;
            report "Completed SLT R" & integer'image(conv_integer(RD)) & " R" & integer'image(conv_integer(RS)) & " R" & integer'image(conv_integer(RT)) severity NOTE;
         elsif FUNC = JR_FUNC then
            PC := regs(conv_integer(RS)) - 4; -- 4 is incremented below.
            report "Completed JR R" & integer'image(conv_integer(RS)) severity NOTE;
         elsif FUNC = SLL_FUNC then
            regs(conv_integer(RD)) := to_stdlogicvector(to_bitvector(regs(conv_integer(RT))) sll conv_integer(SHAMT));
            report "Completed SLL R" & integer'image(conv_integer(RD)) & " R" & integer'image(conv_integer(RT)) & " " & integer'image(conv_integer(SHAMT)) severity NOTE;
         elsif FUNC = NOR_FUNC then
            regs(conv_integer(RD)) := regs(conv_integer(RS)) nor regs(conv_integer(RT));
            report "Completed NOR R" & integer'image(conv_integer(RD)) & " R" & integer'image(conv_integer(RS)) & " R" & integer'image(conv_integer(RT)) severity NOTE;
         else
            report "cpu.vhd: Unknown ALU function" severity ERROR;
            wait; -- Kill the simulation on a bad instruction
         end if;
      elsif OPCODE = BEQ_OP then
         if regs(conv_integer(RS)) = regs(conv_integer(RT)) then
            PC := to_stdlogicvector(to_bitvector(IMM) sll 2) - 4; -- 4 is incremented below.
         end if;
         report "Completed BEQ R" & integer'image(conv_integer(RS)) & " R" & integer'image(conv_integer(RT)) & " " & integer'image(conv_integer(IMM)) severity NOTE;
      elsif OPCODE = J_OP then
         PC := to_stdlogicvector(to_bitvector(ADDRESS) sll 2) - 4; 
      elsif OPCODE = BNE_OP then
         if regs(conv_integer(RS)) /= regs(conv_integer(RT)) then
            PC := to_stdlogicvector(to_bitvector(IMM) sll 2) - 4; -- 4 is incremented below.
         end if;
         report "Completed BNE R" & integer'image(conv_integer(RS)) & " R" & integer'image(conv_integer(RT)) & " " & integer'image(conv_integer(to_stdlogicvector(to_bitvector(IMM) sll 2))) severity NOTE;
      elsif OPCODE = LUI_OP then
         regs(conv_integer(RT)) := to_stdlogicvector(to_bitvector(IMM) sll 16);
         report "Completed LUI R" & integer'image(conv_integer(RT)) & " " & integer'image(conv_integer(IMM)) severity NOTE;
      else
         report "cpu.vhd: Unknown OP Code" severity ERROR;
         wait; -- Kill the simulation on a bad instruction.
      end if;
      
      wait for CYCLE_TIME;
      PC := PC + 4; -- Increment program counter
      wait for CYCLE_TIME;
   end process;
   
end Behavioral;


