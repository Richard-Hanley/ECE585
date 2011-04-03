-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
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
      done  : in    std_logic
   );
end cpu;

architecture Behavioral of cpu is

begin

end Behavioral;


