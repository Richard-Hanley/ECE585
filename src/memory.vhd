-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License:  GPLv3
--
-- Description: This is a combined memory and memory 
--    controller.  The generics specify the neccessary 
--    wait time for the signal to be valid from memory.
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TEXT IO functions for filling RAM
use STD.TEXTIO.ALL;

-- Constants for this project
use WORK.CONSTANTS.ALL;

entity memory is
Generic (
   WRITE_DELAY : integer := MEM_PORT_READ_CYCLES  + MEM_ADD_READ_CYCLES;
   READ_DELAY  : integer := MEM_PORT_WRITE_CYCLES + MEM_ADD_WRITE_CYCLES
);
Port (
   clk   : in    std_logic;
   reset : in    std_logic;
   
   ce    : in    std_logic;
   wr    : in    std_logic;
   done  : out   std_logic;
   
   addr  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
   data  : inout std_logic_vector(BUS_WIDTH-1 downto 0)
);
end memory;

architecture Behavioral of memory is

   -- Function for filling ram with sample program.
   impure function load_ram(file_name : in string) return mem_t is
      FILE ram_file     : text is in file_name;
      variable line_no  : line;
      variable mem      : mem_t;
   begin
      for I in mem_t'range loop
         readline(ram_file, line_no);
         read(line_no, mem(I));
      end loop;
      return mem;
   end function;
   
   signal mem : mem_t := load_ram(PROG_FILENAME);
   signal data_i : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal done_i : std_logic;
   signal accum_rst : std_logic;
   signal accum : std_logic_vector(log2(MEM_PORT_READ_CYCLES + MEM_ADD_READ_CYCLES)-1 downto 0);
   signal accum_overflow : std_logic;
   signal wr_reg : std_logic;
   signal data_reg : std_logic_vector(BUS_WIDTH-1 downto 0);
   
   type mem_states_t is ( NEW_STATE, WAIT_STATE, DONE_STATE );
   signal state, next_state : mem_states_t;
   
begin

   done <= done_i;
   
   -- Data bus tri-state.
   data <= data_i when ce = '1' and wr = '0' and done_i = '1' else (others => 'Z');

   ACCUMULATOR: process(clk, reset, accum_rst, accum)
      variable accum : integer := 0;
   begin
      if rising_edge(clk) then
         if accum_rst = '1' or reset = '1' then
            accum := 0;
         else
            if (accum = READ_DELAY and wr_reg = '0') then
               accum_overflow <= '1';
            elsif (accum = WRITE_DELAY and wr_reg = '1') then
               accum_overflow <= '1';
            else
               accum_overflow <= '0';
               accum := accum + 1;
            end if;
         end if;
      end if;
   end process;
   
   -- This is emulation of one cycle ram which is then manifested
   MEM_ACCESS: process (clk, wr, data)
   begin
      if rising_edge(clk) then
         if wr = '1' then
            if done_i = '1' then
               mem(conv_integer(addr)) <= to_bitvector(data);
            end if;
         else
            data_i <= to_stdlogicvector(mem(conv_integer(ADDR)));
         end if;
      end if;
   end process;
      
   -- done state machine.
   SYNC_PORC: process(clk) 
   begin
      if rising_edge(clk) then
         if reset = '1' then
            state <= NEW_STATE;
            wr_reg <= '0';
            data_reg <= (others => '0');
         else
            state <= next_state;
            wr_reg <= wr;
            data_reg <= data;
         end if;
      end if;
   end process;
   
   OUTPUT_DECODE: process(state)
   begin
      done_i <= '0';
      if state = DONE_STATE then
         done_i <= '1';
      end if;
   end process;
   
   NEXT_STATE_DECODE: process(clk, wr, data, ce)
   begin
      next_state <= state;
      case (state) is
         when NEW_STATE =>
            if (wr = wr_reg and data = data_reg and ce = '1') then
               next_state <= WAIT_STATE;
            end if;
         when WAIT_STATE =>
            if (wr /= wr_reg or data /= data_reg or ce = '0') then
               next_state <= NEW_STATE;
            elsif accum_overflow = '1' then
               next_state <= DONE_STATE;
            end if;
         when DONE_STATE =>
            if (wr /= wr_reg or data /= data_reg or ce = '0') then
               next_state <= NEW_STATE;
            end if;
         when others =>
            report "memory.vhd: Error bad state" severity FAILURE;
      end case;
   end process;

end Behavioral;


