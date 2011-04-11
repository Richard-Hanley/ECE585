-------------------------------------------------------
-- Engineer: Spenser Gilliland
-- License: GPLv3
-------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
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
      
--      -- Interface to icache
--      icache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
--      icache_addr : out    std_logic_vector(log2(ICACHE_DEPTH)-1 downto 0);
--      icache_wr   : out    std_logic;
--      
--      -- Interface to dcache
--      dcache_data : inout std_logic_vector(BUS_WIDTH-1 downto 0);
--      dcache_addr : out    std_logic_vector(log2(DCACHE_DEPTH)-1 downto 0);
--      dcache_wr   : out    std_logic;
      
      -- Interface to CPU
      data_in  : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_in  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      wr_in    : in    std_logic;
      done_out : out   std_logic;
      instr    : in    std_logic; -- If it is currently fetching an instruction.
      
      -- Interface to Memory
      data_out : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_out : out   std_logic_vector(BUS_WIDTH-1 downto 0);
      wr_out   : out   std_logic;
      done_in  : in    std_logic
   );
end cache_ctl;

architecture Behavioral of cache_ctl is
   constant ITAG_WIDTH   : integer := log2(MEM_DEPTH) - log2(ICACHE_DEPTH);
   constant DTAG_WIDTH   : integer := log2(MEM_DEPTH) - log2(DCACHE_DEPTH);
   constant IINDEX_WIDTH : integer := log2(ICACHE_DEPTH);
   constant DINDEX_WIDTH : integer := log2(DCACHE_DEPTH);
   constant IENTRY_WIDTH : integer := ITAG_WIDTH + 1;
   constant DENTRY_WIDTH : integer := DTAG_WIDTH + 1 + 1;
    
   -- Add one to the tag width for the valid bit.  FYI: this is just the tag memory not the cache.
   type itagmem_t is array(ICACHE_DEPTH-1 downto 0) of std_logic_vector(IENTRY_WIDTH - 1 downto 0);
   type dtagmem_t is array(DCACHE_DEPTH-1 downto 0) of std_logic_vector(DENTRY_WIDTH - 1 downto 0);
   type itags_t   is array(WORD_SIZE / BYTE_SIZE - 1 downto 0) of std_logic_vector(IENTRY_WIDTH-1 downto 0);
   type dtags_t   is array(WORD_SIZE / BYTE_SIZE - 1 downto 0) of std_logic_vector(DENTRY_WIDTH-1 downto 0);

   type idatamem_t is array(ICACHE_DEPTH-1 downto 0) of std_logic_vector(BYTE_SIZE-1 downto 0);
   type ddatamem_t is array(DCACHE_DEPTH-1 downto 0) of std_logic_vector(BYTE_SIZE-1 downto 0);
   
   
   
   type cachesm_t is ( IDLE,
                       IREAD,
                       DREAD);
   
   function clear_itags return itagmem_t is
      variable tags : itagmem_t;
   begin
      for I in tags'range loop
         tags(I) := (others => '0');
      end loop;
      return tags;
   end function;
   
   function clear_dtags return dtagmem_t is
      variable tags : dtagmem_t;
   begin
      for I in tags'range loop
         tags(I) := (others => '0');
      end loop;
      return tags;
   end function;
   
   signal ientries : itagmem_t := clear_itags;
   signal dentries : dtagmem_t := clear_dtags;
   signal icache   : idatamem_t;
   signal dcache   : idatamem_t;
   
   signal cache_hit : std_logic;
   
   signal ientry : itags_t;
   signal dentry : dtags_t;
   
   signal ivalid : std_logic;
   signal dvalid : std_logic;
   signal ddirty : std_logic;
   signal icache_tag : std_logic;
   signal dcache_tag : std_logic;
   signal icache_hit : std_logic;
   signal dcache_hit : std_logic;
   
   signal hit : std_logic;
   signal cache_data : std_logic_vector(WORD_SIZE-1 downto 0);
   
   signal state, next_state : cachesm_t := IDLE;
   
   alias itag_in : std_logic_vector(ITAG_WIDTH-1 downto 0) is addr_in(log2(MEM_DEPTH) - 1 downto log2(MEM_DEPTH) - ITAG_WIDTH);  
   alias dtag_in : std_logic_vector(DTAG_WIDTH-1 downto 0) is addr_in(log2(MEM_DEPTH) - 1 downto log2(MEM_DEPTH) - DTAG_WIDTH);
   alias iindex_in : std_logic_vector(IINDEX_WIDTH-1 downto 0) is addr_in(IINDEX_WIDTH - 1 downto 0);
   alias dindex_in : std_logic_vector(DINDEX_WIDTH-1 downto 0) is addr_in(DINDEX_WIDTH - 1 downto 0);   
   
begin

   ientry <= ientries(conv_integer(iindex) + WORD_SIZE / BYTE_SIZE downto conv_integer(iindex));
   dentry <= dentries(conv_integer(dindex) + WORD_SIZE / BYTE_SIZE downto conv_integer(dindex));
   
   -- All of the valid bits must be set for the addr to be valid. TODO: Make this generic
   ivalid <= ientry(0)(ITAG_WIDTH) and ientry(1)(ITAG_WIDTH) and 
             ientry(2)(ITAG_WIDTH) and ientry(3)(ITAG_WIDTH);
   dvalid <= dentry(0)(DTAG_WIDTH) and dentry(1)(DTAG_WIDTH) and 
             dentry(2)(DTAG_WIDTH) and dentry(3)(DTAG_WIDTH);

   -- If any of the dirty bits are set it's dirty TODO: Make this generic
   ddirty <= dentry(0)(DTAG_WIDTH + 1) or dentry(1)(DTAG_WIDTH + 1) or 
             dentry(2)(DTAG_WIDTH + 1) or dentry(3)(DTAG_WIDTH + 1);

   -- If any of the tags are not correct then not a hit. TODO: Make it so this only uses a single N way comparator.
   icache_tag <= '1' when itag_in = ientry(0)(ITAG_WIDTH-1 downto 0) and 
                          itag_in = ientry(1)(ITAG_WIDTH-1 downto 0) and 
                          itag_in = ientry(2)(ITAG_WIDTH-1 downto 0) and 
                          itag_in = ientry(3)(ITAG_WIDTH-1 downto 0) else '0'; 
   dcache_tag <= '1' when dtag_in = dentry(0)(DTAG_WIDTH-1 downto 0) and 
                          dtag_in = dentry(1)(DTAG_WIDTH-1 downto 0) and 
                          dtag_in = dentry(2)(DTAG_WIDTH-1 downto 0) and 
                          dtag_in = dentry(3)(DTAG_WIDTH-1 downto 0) else '0';
   
   -- A hit occurs when the tag matches and the data is valid.
   icache_hit <= icache_tag and ivalid;
   dcache_hit <= dcache_tag and dvalid;
   
   -- Multiplex depending on instr or data access. TODO: Make this Generic.
   cache_data <= icache(conv_integer(iindex) + 4 downto conv_integer(iindex)) 
                 when instr = '1' 
                 else dcache(conv_integer(dindex) + 4 downto conv_integer(dindex));
                 
   hit <= icache_hit when instr = '1' else dcache_hit;
   
   -- Bypass the cache if the data is not in cache;
   addr_out <= cntr      when hit = '1' or wr_in = '1' else addr_in;
   data_in <= cache_data when hit = '1'                else data_out;
   done_out <= '1'       when hit = '1'                else done_in;
   
   -- Write through mode
   wr_out <= wr_in;
   
   -- Cache statemachine
   SYNC_PROC: process(clk, reset, next_state, cntr, addr_in, hit)
   begin
      if rising_edge(clk) then
         if reset = '1' then
            state <= IDLE;
            cntr <= (others => '0');
            start_address <= (others => '0');
         else
            if state = IDLE and (next_state = IREAD or next_state = DREAD)  then
               cntr <= addr_in;
               start_address <= addr_in;
            else
               if done_in = '1' and hit = '1' then -- Essentially if we have a situation where this is going on in the background.
                  cntr <= cntr + 4;
               end if;
            end if;
            state <= next_state;
         end if;
      end if;
   end process;
   
   OUTPUT_DECODE: process(state, next_state, cntr)
   begin
      if state = IREAD then
         icache(conv_integer(cntr(IINDEX-1 downto 0))) <= data_out when done_in = '1';
      elsif state = DREAD then
         dcache(conv_integer(cntr(DINDEX-1 downto 0))) <= data_out when done_in = '1';
      end if;
   end process;
   
   NEXT_STATE_DECODE: process(clk, state, icache_hit, dcache_hit, instr)
   begin
      next_state <= state;
      case (state) is
         when IDLE =>
            if icache_hit = '0' and instr = '1' then
               next_state <= IREAD;
            elsif dcache_hit = '0' and instr = '0' then
               next_state <= DREAD;
            end if;
         when IREAD =>
            if cntr > start_address + BLOCK_SIZE / BYTE_SIZE then
               next_state <= IDLE;
            end if; 
         when DREAD => 
            if cntr > start_address + BLOCK_SIZE / BYTE_SIZE then
               next_state <= IDLE;
            end if;
         when others =>
            report "cache_ctl.vhd: Error bad state" severity FAILURE;
      end case;
   end process;

end Behavioral;

