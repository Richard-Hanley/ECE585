-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
--
-- Description: This is a memory controller.
--
-- Theory of Operation:
--    It is assumed that it takes a number of cycles to 
--    switch from read mode to write mode and an 
--    additional number of cycles to read or write once
--    in the correct mode.  The done state machine of 
--    this code sets the done bit when the write or 
--    read has completed otherwise it clears the done
--    bit.
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use WORK.CONSTANTS.ALL;

entity memory_ctl is
   Generic (
      RD_INIT_CYCLES : integer := MEM_PORT_READ_CYCLES - MEM_ADD_READ_CYCLES;
      WR_INIT_CYCLES : integer := MEM_PORT_WRITE_CYCLES - MEM_ADD_WRITE_CYCLES;
      RD_DATA_CYCLES : integer := MEM_ADD_READ_CYCLES;
      WR_DATA_CYCLES : integer := MEM_ADD_WRITE_CYCLES 
   );
   Port (
      clk   : in    std_logic;
      reset : in    std_logic;
      
      -- Interface to Memory
      data : inout  std_logic_vector(BUS_WIDTH-1 downto 0);
      addr : out    std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      wr   : out    std_logic;

      -- Interface to Cache
      data_in   : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_in   : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      wr_in     : in    std_logic;
      done_out  : out   std_logic
   );
end memory_ctl;

architecture Behavioral of memory_ctl is
   -- Because this memory controller is actually running at bus rate,
   -- the number of cycles must be multiplied by the BW multiplier.
   constant RD_INIT_BUS_CYCLES : integer := RD_INIT_CYCLES * BUS_BW;
   constant WR_INIT_BUS_CYCLES : integer := WR_INIT_CYCLES * BUS_BW;
   constant RD_DATA_BUS_CYCLES : integer := RD_DATA_CYCLES * BUS_BW - 1; -- Minus one due to ready cycle.
   constant WR_DATA_BUS_CYCLES : integer := WR_DATA_CYCLES * BUS_BW - 1; -- Minus one due to ready cycle.
   
   -- Signals for done state machine.
   type memory_ctl_t is ( RD_INIT,  -- Wait for data to be ready for read
                          RD_READY, -- Data is ready to be read (single cycle wait for reseting the cycle counter)
                          RD_DATA,  -- Read data 
                          RD_DONE,  -- Done with read (set done bit)
                          WR_INIT,  -- Similar to RD_INIT
                          WR_READY, -- Similar to RD_READY
                          WR_DATA,  -- Similar to RD_DATA
                          WR_DONE); -- Similar to RD_DONE
   signal state, next_state : memory_ctl_t;
   
   -- Registers for the addr, data, and wr signals
   signal addr_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal data_reg : std_logic_vector(BUS_WIDTH-1 downto 0);
   
   -- Counter signal
   constant CNTR_WIDTH : integer := log2(max4(RD_INIT_BUS_CYCLES, 
                                              WR_INIT_BUS_CYCLES, 
                                              RD_DATA_BUS_CYCLES, 
                                              WR_DATA_BUS_CYCLES));
   constant CNTR_MAX : integer := 2**CNTR_WIDTH - 1;
   signal cntr     : std_logic_vector(CNTR_WIDTH-1 downto 0);
   
begin
   
   data <= data_in when wr_in = '1' else (others => 'Z');
   data_in <= data when wr_in = '0' else (others => 'Z');
   
   addr <= addr_in(log2(MEM_DEPTH)-1 downto 0);
   wr   <= wr_in;

   -- Register the data, addr and write signals to be able to detect changes
   REG_PROC: process(clk, wr_in, addr_in, data_in) 
   begin
      if rising_edge(clk) then
         addr_reg <= addr_in;
         data_reg <= data_in;
      end if;
   end process;
      
   -- State Machine for determining when the outputs are done.
   SYNC_PROC: process(clk, reset, next_state, cntr)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            state <= RD_INIT;
            cntr <= (others => '0');
         else
            if (state /= next_state) then
               cntr <= (others => '0');
            else
               if cntr /= conv_std_logic_vector(CNTR_MAX, CNTR_WIDTH) then
                  cntr <= cntr + 1;
               end if;
            end if;
            state <= next_state;
         end if;
      end if;
   end process;
   
   -- done state machine see appendix A.1 of report.
   OUTPUT_DECODE: process(state, next_state)
   begin
      done_out <= '0';
      if state = RD_DONE or state = WR_DONE then
         done_out <= '1';
      end if;
   end process;
   
   NEXT_STATE_DECODE: process(clk, state, wr_in, data_in, addr_in, cntr, addr_reg, data_reg)
   begin
      next_state <= state;
      case (state) is
         when RD_INIT =>
            if wr_in = '0' then
               if cntr > RD_INIT_BUS_CYCLES then
                  next_state <= RD_READY;
               end if;
            else
               next_state <= WR_INIT;
            end if;
         when RD_READY =>
            if wr_in = '0' then
               next_state <= RD_DATA;
            else
               report "memory_ctl.vhd: 0: Incomplete read operation" severity ERROR;
               next_state <= WR_INIT;
            end if;
         when RD_DATA => 
            if wr_in = '0' then
               if addr_in = addr_reg then
                  if cntr > RD_DATA_BUS_CYCLES then
                     next_state <= RD_DONE;
                  end if;
               else
                  report "memory_ctl.vhd: 1: Incomplete read operation" severity ERROR;
                  next_state <= RD_READY;
               end if;
            else
               report "memory_ctl.vhd: 2: Incomplete read operation" severity ERROR;
               next_state <= WR_INIT;
            end if;
         when RD_DONE =>
            if wr_in = '0' then
               if addr_in /= addr_reg then 
                  next_state <= RD_READY;
               end if;
            else
               next_state <= WR_INIT;
            end if;
         when WR_INIT =>
            if wr_in = '1' then 
               if cntr > WR_INIT_BUS_CYCLES then
                  next_state <= WR_READY;
               end if;
            else
               next_state <= RD_INIT;
            end if;
         when WR_READY =>
            if wr_in = '1' then
               next_state <= WR_DATA;
            else
               report "memory_ctl.vhd: 0: Incomplete write operation" severity ERROR;
               next_state <= RD_INIT;
            end if;
         when WR_DATA  =>
            if wr_in = '1' then
               if addr_in = addr_reg and data_in = data_reg then
                  if cntr > WR_DATA_BUS_CYCLES then
                     next_state <= WR_DONE;
                  end if;
               else
                  report "memory_ctl.vhd: 1:Incomplete write operation" severity ERROR;
                  next_state <= WR_READY;
               end if;
            else
               report "memory_ctl.vhd: 2: Incomplete write operation" severity ERROR;
               next_state <= RD_INIT;
            end if;
         when WR_DONE  =>
            if wr_in = '1' then 
               if addr_in /= addr_reg or data_in /= data_reg then
                  next_state <= WR_READY;
               end if;
            else
               next_state <= RD_INIT;
            end if;
         when others =>
            report "memory_ctl.vhd: Error bad state" severity FAILURE;
      end case;
   end process;
   
end Behavioral;

