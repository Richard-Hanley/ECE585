-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORK.CONSTANTS.ALL;

entity top is
   Port (
      clk       : in std_logic;
      bus_clk   : in std_logic;
      mem_clk   : in std_logic;
      cache_clk : in std_logic; 
      reset     : in std_logic;
      
      -- Interface to Memory
      mem_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      mem_addr : in    std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      mem_wr   : in    std_logic;
      
      -- Interface to ICache
      icache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      icache_addr : in    std_logic_vector(log2(ICACHE_DEPTH)-1 downto 0);
      icache_wr   : in    std_logic;
      
      -- Interface to DCache
      dcache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      dcache_addr : in    std_logic_vector(log2(DCACHE_DEPTH)-1 downto 0);
      dcache_wr   : in    std_logic
   );
end top;

architecture Behavioral of top is
   signal cache_cpu_data : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal cache_cpu_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal cache_cpu_wr   : std_logic;
   signal cache_cpu_done : std_logic;
   
   signal mem_cache_data : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal mem_cache_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal mem_cache_wr   : std_logic;
   signal mem_cache_done : std_logic;
   
   component cpu is
      Port (
         clk   : in    std_logic;
         reset : in    std_logic;
         
         -- Interface to Cache
         data  : inout std_logic_vector(BUS_WIDTH-1  downto 0);
         addr  : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
         wr    : out   std_logic;
         done  : in    std_logic
      );
   end component;
      
   component cache_ctl is
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
         icache_addr : in    std_logic_vector(log2(ICACHE_DEPTH)-1 downto 0);
         icache_wr   : in    std_logic;
         
         -- Interface to dcache
         dcache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         dcache_addr : in    std_logic_vector(log2(DCACHE_DEPTH)-1 downto 0);
         dcache_wr   : in    std_logic;
         
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
   end component;
      
   component memory_ctl is
      Generic (
         READ_DELAY  : integer := 0;
         WRITE_DELAY : integer := 0
      );
      Port (
         clk   : in    std_logic;
         reset : in    std_logic;
         
         -- Interface to Memory
         data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         addr : in    std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
         wr   : in    std_logic;

         -- Interface to Cache
         data_in   : inout std_logic_vector(BUS_WIDTH-1 downto 0);
         addr_in   : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
         wr_in     : in    std_logic;
         done_out  : out   std_logic
      );
   end component;
      
begin
   GEN_NOCACHE : if NOCACHE = '1' generate
   begin
      NCPU_INST: cpu
      Port map(
         clk   => clk,
         reset => reset,
         
         -- Interface to Cache
         data  => cache_cpu_data,
         addr  => cache_cpu_addr,
         wr    => cache_cpu_wr,
         done  => cache_cpu_done
      );
      
   NMEM_CTL: memory_ctl
      Port map (
         clk   => bus_clk,
         reset => reset,
         
         -- Interface to Memory
         data => mem_data,
         addr => mem_addr,
         wr   => mem_wr,

         -- Interface to Cache
         data_in  => cache_cpu_data,
         addr_in  => cache_cpu_addr,
         wr_in    => mem_cache_wr,
         done_out => cache_cpu_done     
      );
      
   
      CPU_INST: cpu
      Port map(
         clk   => clk,
         reset => reset,
         
         -- Interface to Cache
         data  => cache_cpu_data,
         addr  => cache_cpu_addr,
         wr    => cache_cpu_wr,
         done  => cache_cpu_done
      );
   end generate;
   
   GEN_CACHE : if NOCACHE = '0' generate   
   C_CTL: cache_ctl
      Port map (
         clk     => clk,
         bus_clk => bus_clk,
         reset   => reset,
         
         -- Interface to icache
         icache_data => icache_data,
         icache_addr => icache_addr,
         icache_wr   => icache_wr,
         
         -- Interface to dcache
         dcache_data => dcache_data,
         dcache_addr => dcache_addr,
         dcache_wr   => dcache_wr,
         
         -- Interface to CPU
         data_in  => cache_cpu_data,
         addr_in  => cache_cpu_addr,
         wr_in    => cache_cpu_wr,
         done_out => cache_cpu_done,
         
         -- Interface to Memory
         data_out => mem_cache_data,
         addr_out => mem_cache_addr,
         wr_out   => mem_cache_wr,
         done_in  => mem_cache_done
      );
      
   MEM_CTL: memory_ctl
      Port map (
         clk   => bus_clk,
         reset => reset,
         
         -- Interface to Memory
         data => mem_data,
         addr => mem_addr,
         wr   => mem_wr,

         -- Interface to Cache
         data_in  => mem_cache_data,
         addr_in  => mem_cache_addr,
         wr_in    => mem_cache_wr,
         done_out => mem_cache_done     
      );
   end generate;
   




end Behavioral;


