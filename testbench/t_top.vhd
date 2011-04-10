-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORK.CONSTANTS.ALL;
 
entity t_top is
end t_top;
 
architecture behavior of t_top is 
 
    -- Component Declaration for the Unit Under Test (UUT)
   component top
      Port (
         clk       : in std_logic;
         bus_clk   : in std_logic;
         reset     : in std_logic;
         
         -- Interface to CPU
         data     : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         addr     : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
         wr       : in    std_logic;
         done     : out   std_logic;
         
         -- Interface to Memory
         mem_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         mem_addr : out   std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
         mem_wr   : out   std_logic;
         
         -- Interface to ICache
         icache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         icache_addr : out   std_logic_vector(log2(ICACHE_DEPTH)-1 downto 0);
         icache_wr   : out   std_logic;
         
         -- Interface to DCache
         dcache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         dcache_addr : out   std_logic_vector(log2(DCACHE_DEPTH)-1 downto 0);
         dcache_wr   : out   std_logic
      );
   end component;
    
   component cpu 
      Port (
         clk   : in    std_logic;
         reset : in    std_logic;
         
         -- Interface to Memory Hierarchy
         data  : inout std_logic_vector(BUS_WIDTH-1  downto 0);
         addr  : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
         wr    : out   std_logic;
         done  : in    std_logic
      );
   end component;
   
   component mem_elem
      Generic (
         ELEM_DEPTH  : integer := MEM_DEPTH;
         LD_FILENAME : string  := "zeros.hex"
      );
      Port (
         data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         addr : in    std_logic_vector(log2(ELEM_DEPTH)-1 downto 0);
         wr   : in    std_logic
      );
   end component;
   
   signal clk         : std_logic;
   signal bus_clk     : std_logic;
   signal mem_clk     : std_logic;
   signal cache_clk   : std_logic;
   signal reset       : std_logic;
   signal data        : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal addr        : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal wr          : std_logic;
   signal done        : std_logic;
   signal mem_data    : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal mem_addr    : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
   signal mem_wr      : std_logic;
   signal icache_data : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal icache_addr : std_logic_vector(log2(ICACHE_DEPTH)-1 downto 0);
   signal icache_wr   : std_logic;
   signal dcache_data : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal dcache_addr : std_logic_vector(log2(DCACHE_DEPTH)-1 downto 0);
   signal dcache_wr   : std_logic;
   
begin

   -- Clock process definitions
   clk_process: process
   begin
		clk <= '0';
		wait for CYCLE_TIME/2;
		clk <= '1';
		wait for CYCLE_TIME/2;
   end process;
   
   bus_clk_process: process
   begin
      bus_clk <= '0';
      wait for BUS_CYCLE_TIME/2;
      bus_clk <= '1';
      wait for BUS_CYCLE_TIME/2;
   end process;
      
   uut: top
      Port Map (
         clk         => clk,
         bus_clk     => bus_clk,
         reset       => reset,
         -- Interface to CPU
         data        => data,
         addr        => addr,
         wr          => wr,
         done        => done,
         -- Interface to Memory
         mem_data    => mem_data,
         mem_addr    => mem_addr,
         mem_wr      => mem_wr,
         -- Interface to ICache
         icache_data => icache_data,
         icache_addr => icache_addr,
         icache_wr   => icache_wr,
         -- Interface to DCache
         dcache_data => dcache_data,
         dcache_addr => dcache_addr,
         dcache_wr   => dcache_wr
      );
   
   cpu_inst: cpu
      Port map (
         clk   => clk,
         reset => reset,
         
         -- Interface to Memory Hierarchy
         data  => data,
         addr  => addr,
         wr    => wr,
         done  => done
      );

   mem: mem_elem
      Generic map (
         ELEM_DEPTH => MEM_DEPTH,
         LD_FILENAME => PROG_FILENAME
      )
      Port map (
         data => mem_data,
         addr => mem_addr,
         wr   => mem_wr
      );       
      
   dcache: mem_elem
      Generic map (
         ELEM_DEPTH => DCACHE_DEPTH
      )
      Port map (
         data => dcache_data,
         addr => dcache_addr,
         wr   => dcache_wr
      );

   icache: mem_elem
      Generic map (
         ELEM_DEPTH => ICACHE_DEPTH
      )
      Port map (
         data => icache_data,
         addr => icache_addr,
         wr   => icache_wr
      );
   
   -- Stimulus process
   stim_proc: process
   begin
      reset <= '1';
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CYCLE_TIME*10;      
      -- insert stimulus here
      
      reset <= '0'; -- start the magic happening.
      
      wait;
   end process;

end;
