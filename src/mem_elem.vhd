-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TEXT IO functions for filling RAM
use STD.TEXTIO.ALL;
--use STD.TEXTIO_UTIL.ALL;

-- Constants for this project
use WORK.CONSTANTS.ALL;

entity mem_elem is
   Generic (
      ELEM_DEPTH  : integer := MEM_DEPTH;
      LD_FILENAME : string  := "zeros.hex" -- load all zeros.
   );
   Port (
      data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr : in    std_logic_vector(log2(ELEM_DEPTH)-1 downto 0);
      wr   : in    std_logic
   );
end mem_elem;

architecture Behavioral of mem_elem is

   type mem_t is array(ELEM_DEPTH-1 downto 0) of std_logic_vector(BYTE_SIZE-1 downto 0);
   
   -- Function for filling ram with sample program.
   impure function load_ram(file_name : in string) return mem_t is
      FILE ram_file     : text is in file_name;
      variable line_no  : line;
      variable mem      : mem_t;
      variable temp     : std_logic_vector(31 downto 0);
   begin
      for I in 0 to ELEM_DEPTH / 4 - 1 loop
         readline(ram_file, line_no);
         hread(line_no, temp);
         mem(I * 4)     := temp(    BYTE_SIZE - 1 downto 0);
         mem(I * 4 + 1) := temp(2 * BYTE_SIZE - 1 downto     BYTE_SIZE);
         mem(I * 4 + 2) := temp(3 * BYTE_SIZE - 1 downto 2 * BYTE_SIZE);
         mem(I * 4 + 3) := temp(4 * BYTE_SIZE - 1 downto 3 * BYTE_SIZE);
      end loop;
      return mem;
   end function;

   signal mem : mem_t := load_ram(LD_FILENAME);
begin
   -- Create a single cycle ram for testing.
   MEM_ACCESS: process (wr, data, addr, mem)
      variable iaddr : integer := conv_integer(addr);
   begin
      if wr = '1' then
         data <= (others => 'Z');
         mem(conv_integer(addr))     <= data(    BYTE_SIZE - 1 downto 0            );
         mem(conv_integer(addr + 1)) <= data(2 * BYTE_SIZE - 1 downto     BYTE_SIZE);
         mem(conv_integer(addr + 2)) <= data(3 * BYTE_SIZE - 1 downto 2 * BYTE_SIZE);
         mem(conv_integer(addr + 3)) <= data(4 * BYTE_SIZE - 1 downto 3 * BYTE_SIZE);
      else
         data(    BYTE_SIZE - 1 downto 0)             <= mem(conv_integer(addr    ));
         data(2 * BYTE_SIZE - 1 downto     BYTE_SIZE) <= mem(conv_integer(addr + 1));
         data(3 * BYTE_SIZE - 1 downto 2 * BYTE_SIZE) <= mem(conv_integer(addr + 2));
         data(4 * BYTE_SIZE - 1 downto 3 * BYTE_SIZE) <= mem(conv_integer(addr + 3));
      end if;
   end process;
end Behavioral;

