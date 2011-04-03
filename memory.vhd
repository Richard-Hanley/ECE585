-------------------------------------------------------
-- Engineer: Spenser Gilliland & Richard Hanley
-- License:  GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TEXT IO functions for filling RAM
use STD.TEXTIO.ALL;

-- Constants for this project
use WORK.CONSTANTS.ALL;

entity memory is
Generic 
Port (
   clk   : in    std_logic;
   reset : in    std_logic;
   
   ce    : in    std_logic;
   wr    : in    std_logic;
   done  : out   std_logic;
   
   addr  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
   data  : inout std_logic_vector(BUS_WIDTH-1 downto 0);
);
end memory;

architecture Behavioral of memory is

   -- Function for filling ram with sample program.
   impure function load_ram(file_name : in string) return mem_t is
      FILE ram_file     : text is in file_name;
      variable line_no : line;
      variable mem  : mem_t;
   begin
      for I in mem_t'range loop
         readline(ram_file, line_no);
         read(line_no, mem(I));
      end loop;
      return mem;
   end function;
   
   signal mem : mem_t := load_ram(PROG_FILENAME);
   signal data_i : data'type;
   
begin
   
   -- Data bus tri-state.
   data <= data_i when ce = '1' else (others => 'Z');
   
   process (clk, wr, data);
   begin
      if rising_edge(clk) then
         if wr = '1' then
            mem(conv_integer(addr)) <= data_in after MEM_WRITE_TIME;
         end if;
         data_out <= RAM(conv_integer(ADDR)) after MEM_READ_TIME;
      end if;
   end process;

end Behavioral;


