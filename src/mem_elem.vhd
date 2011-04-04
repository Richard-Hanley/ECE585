-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TEXT IO functions for filling RAM
use STD.TEXTIO.ALL;

-- Constants for this project
use WORK.CONSTANTS.ALL;

entity mem_elem is
   Generic (
      ELEM_WIDTH  : integer := ADDR_WIDTH;
      LD_FILENAME : string  := "zeros.hex" -- load all zeros.
   );
   Port (
      data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr : in    std_logic_vector(ELEM_WIDTH-1 downto 0);
      wr   : in    std_logic
   );
end mem_elem;

architecture Behavioral of mem_elem is

   type mem_t is array(ELEM_WIDTH-1 downto 0) of std_logic_vector(WORD_SIZE-1 downto 0);
   
   -- Function for filling ram with sample program.
   impure function load_ram(file_name : in string) return mem_t is
      FILE ram_file     : text is in file_name;
      variable line_no  : line;
      variable mem      : mem_t;
      variable temp     : bit_vector(WORD_SIZE-1 downto 0);
   begin
      for I in mem_t'range loop
         readline(ram_file, line_no);
         read(line_no, temp);
         mem(I) := to_stdlogicvector(temp);
      end loop;
      return mem;
   end function;

   signal mem : mem_t := load_ram(LD_FILENAME);
begin
   -- Create a single cycle ram for testing.
   MEM_ACCESS: process (wr, data)
   begin
      if wr = '1' then
         mem(conv_integer(addr)) <= data;
      else
         data <= mem(conv_integer(ADDR));
      end if;
   end process;
end Behavioral;

