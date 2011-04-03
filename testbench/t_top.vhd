-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;
 
ENTITY t_top IS
END t_top;
 
ARCHITECTURE behavior OF t_top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top
    PORT(
         clk : IN  std_logic;
         bus_clk : IN  std_logic;
         mem_clk : IN  std_logic;
         cache_clk : IN  std_logic;
         reset : IN  std_logic;
         mem_data : INOUT  std_logic_vector(31 downto 0);
         mem_addr : IN  std_logic_vector(64 downto 0);
         mem_wr : IN  std_logic;
         icache_data : INOUT  std_logic_vector(31 downto 0);
         icache_addr : IN  std_logic_vector(64 downto 0);
         icache_wr : IN  std_logic;
         dcache_data : INOUT  std_logic_vector(31 downto 0);
         dcache_addr : IN  std_logic_vector(64 downto 0);
         dcache_wr : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal bus_clk : std_logic := '0';
   signal mem_clk : std_logic := '0';
   signal cache_clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal mem_addr : std_logic_vector(64 downto 0) := (others => '0');
   signal mem_wr : std_logic := '0';
   signal icache_addr : std_logic_vector(64 downto 0) := (others => '0');
   signal icache_wr : std_logic := '0';
   signal dcache_addr : std_logic_vector(64 downto 0) := (others => '0');
   signal dcache_wr : std_logic := '0';

	--BiDirs
   signal mem_data : std_logic_vector(31 downto 0);
   signal icache_data : std_logic_vector(31 downto 0);
   signal dcache_data : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant bus_clk_period : time := 10 ns;
   constant mem_clk_period : time := 10 ns;
   constant cache_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk => clk,
          bus_clk => bus_clk,
          mem_clk => mem_clk,
          cache_clk => cache_clk,
          reset => reset,
          mem_data => mem_data,
          mem_addr => mem_addr,
          mem_wr => mem_wr,
          icache_data => icache_data,
          icache_addr => icache_addr,
          icache_wr => icache_wr,
          dcache_data => dcache_data,
          dcache_addr => dcache_addr,
          dcache_wr => dcache_wr
        );

   -- Clock process definitions
   clk_process: process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   bus_clk_process: process
   begin
		bus_clk <= '0';
		wait for bus_clk_period/2;
		bus_clk <= '1';
		wait for bus_clk_period/2;
   end process;
 
   mem_clk_process: process
   begin
		mem_clk <= '0';
		wait for mem_clk_period/2;
		mem_clk <= '1';
		wait for mem_clk_period/2;
   end process;
 
   cache_clk_process: process
   begin
		cache_clk <= '0';
		wait for cache_clk_period/2;
		cache_clk <= '1';
		wait for cache_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
