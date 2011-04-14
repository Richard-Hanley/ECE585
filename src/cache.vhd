-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use WORK.CONSTANTS.ALL;

entity cache is
   Generic (
      CACHE_DEPTH : integer := ICACHE_DEPTH
   );
   Port (
      clk      : in  std_logic;
      bus_clk  : in  std_logic;
      
      -- Interface to CPU
      addr_check : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_out   : out std_logic_vector(BUS_WIDTH-1 downto 0);
      hit        : out std_logic;
      
      -- Inteface to fill SM
      addr_fill  : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_in    : in  std_logic_vector(BUS_WIDTH-1 downto 0);
      wr         : in  std_logic
   );
end cache;

architecture Behavioral of cache is
   constant VALID_BIT   : integer := 1;
   constant TAG_WIDTH   : integer := log2(MEM_DEPTH) - log2(CACHE_DEPTH) - log2(4);
   constant INDEX_WIDTH : integer := log2(CACHE_DEPTH);
   constant ENTRY_WIDTH : integer := VALID_BIT + TAG_WIDTH + WORD_SIZE;

   type cache_t is array(CACHE_DEPTH-1 downto 0) of std_logic_vector(ENTRY_WIDTH - 1 downto 0);
   
   function clear_cache return cache_t is
      variable cache : cache_t;
   begin
      for I in cache'range loop
         cache(I) := (others => '0');
      end loop;
      return cache;
   end function;
   
   shared variable cache : cache_t := clear_cache;
   
   signal check_entry : std_logic_vector(ENTRY_WIDTH-1 downto 0);
   signal fill_entry  : std_logic_vector(ENTRY_WIDTH-1 downto 0);
   
   alias check_tag_in : std_logic_vector(TAG_WIDTH-1 downto 0)   is addr_check(log2(MEM_DEPTH)-1 downto log2(MEM_DEPTH) - TAG_WIDTH);
   alias check_index  : std_logic_vector(INDEX_WIDTH-1 downto 0) is addr_check(log2(MEM_DEPTH)-TAG_WIDTH - 1 downto log2(MEM_DEPTH)-TAG_WIDTH-INDEX_WIDTH);
   
   alias check_valid  : std_logic is check_entry(ENTRY_WIDTH-1);
   alias check_tag    : std_logic_vector(TAG_WIDTH-1 downto 0) is checK_entry(ENTRY_WIDTH-2 downto ENTRY_WIDTH-1-TAG_WIDTH);
   alias check_data   : std_logic_vector(BUS_WIDTH-1 downto 0) is check_entry(BUS_WIDTH-1 downto 0);
   
   alias fill_tag_in : std_logic_vector(TAG_WIDTH-1 downto 0)   is addr_fill(log2(MEM_DEPTH)-1 downto log2(MEM_DEPTH) - TAG_WIDTH); 
   alias fill_index  : std_logic_vector(INDEX_WIDTH-1 downto 0) is addr_fill(log2(MEM_DEPTH)-TAG_WIDTH-1 downto log2(MEM_DEPTH)-TAG_WIDTH-INDEX_WIDTH);
   
   alias fill_valid  : std_logic is fill_entry(ENTRY_WIDTH-1);
   alias fill_tag    : std_logic_vector(TAG_WIDTH-1 downto 0) is fill_entry(ENTRY_WIDTH-2 downto ENTRY_WIDTH-1-TAG_WIDTH);
   alias fill_data   : std_logic_vector(BUS_WIDTH-1 downto 0) is fill_entry(BUS_WIDTH-1 downto 0);
   
   signal aligned : std_logic;
   signal fill_aligned : std_logic;
   
begin

   -- Don't accept misaligned hits (would require two accesses to cache or multiple read ports)
   aligned <= '1' when addr_check(1 downto 0) = "00" else '0';
   hit <= '1' when aligned = '1' and check_valid = '1' and check_tag = check_tag_in else '0'; 
   data_out <= check_data;
   
   --MEM_ACCESS: process(clk) 
  -- begin
      --report "cache.vhd: log2(MEM_DEPTH) is " & integer'image(log2(MEM_DEPTH)) severity NOTE;
     -- if rising_edge(clk) then
         check_entry <= cache(conv_integer(check_index));
    --  end if;
   --end process;

   fill_aligned <= '1' when addr_fill(1 downto 0) = "00" else '0';
   fill_tag <= fill_tag_in;
   fill_valid  <= '1';
   fill_data   <= data_in when fill_aligned = '1' else (others => 'Z');
   
   MEM_WRITE: process(bus_clk)
   begin
      if rising_edge(bus_clk) then
         if wr = '1' then 
            cache(conv_integer(fill_index)) := fill_entry;
         end if;
      end if;
   end process;  

end Behavioral;

