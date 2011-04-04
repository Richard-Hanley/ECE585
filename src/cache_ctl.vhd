-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;

entity cache_ctl is
   Generic (
      READ_DELAY  : integer := CACHE_ACCESS_CYCLES;
      WRITE_DELAY : integer := CACHE_ACCESS_CYCLES
   );
   Port (
      clk     : in    std_logic;
      bus_clk : in    std_logic;
      reset   : in    std_logic;
      
      -- Interface to icache
      icache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      icache_addr : out    std_logic_vector(log2(ICACHE_DEPTH)-1 downto 0);
      icache_wr   : out    std_logic;
      
      -- Interface to dcache
      dcache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      dcache_addr : out    std_logic_vector(log2(DCACHE_DEPTH)-1 downto 0);
      dcache_wr   : out    std_logic;
      
      -- Interface to CPU
      data_in  : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_in  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      wr_in    : in    std_logic;
      done_out : out   std_logic;
      
      -- Interface to Memory
      data_out : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_out : out   std_logic_vector(BUS_WIDTH-1 downto 0);
      wr_out   : out   std_logic;
      done_in  : in    std_logic
   );
end cache_ctl;

architecture Behavioral of cache_ctl is

begin
   -- Currently bypass the cache until we have the CPU operating correctly.
   done_out <= done_in;
   wr_out <= wr_in;
   addr_out <= addr_in;
   data_out <= data_in;
   
end Behavioral;

