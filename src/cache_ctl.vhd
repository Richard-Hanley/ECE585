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
      
      -- Interface to CPU
      data_in  : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_in  : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      wr_in    : in    std_logic;
      done_out : out   std_logic;
      instr    : in    std_logic; -- If it is currently fetching an instruction.
      busy     : in    std_logic;
      
      -- Interface to Memory
      data_out : inout std_logic_vector(BUS_WIDTH-1 downto 0);
      addr_out : out   std_logic_vector(BUS_WIDTH-1 downto 0);
      wr_out   : out   std_logic;
      done_in  : in    std_logic
   );
end cache_ctl;

architecture Behavioral of cache_ctl is
   type cachesm_t is ( IDLE,
                       IREAD,
                       DREAD);
   signal state, next_state : cachesm_t := IDLE;
   
   component cache is
   Generic (
      CACHE_DEPTH : integer := ICACHE_DEPTH
   );
   Port (
      clk      : in  std_logic;
      bus_clk  : in  std_logic;
      reset    : in  std_logic;
      
      -- Interface to CPU
      addr_check : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_out   : out std_logic_vector(BUS_WIDTH-1 downto 0);
      hit        : out std_logic;
      
      -- Inteface to fill SM
      addr_fill  : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_in    : in  std_logic_vector(BUS_WIDTH-1 downto 0);
      wr         : in  std_logic
   );
   end component;
   
   -- Signals for Cache connections
   signal idata, ddata : std_logic_vector(BUS_WIDTH-1 downto 0);
   signal ihit, dhit   : std_logic;
   signal iwr, dwr     : std_logic;
   -- Signals for SM
   signal filler_addr  : std_logic_vector(ADDR_WIDTH-1 downto 0);   
   signal start_addr   : std_logic_vector(ADDR_WIDTH-1 downto 0);
   signal cntr         : std_logic_vector(log2(BLOCK_SIZE/WORD_SIZE) downto 0);
   signal smpause      : std_logic;

begin
   ICACHE: cache
      Generic map (
         CACHE_DEPTH => ICACHE_DEPTH
      )
      Port map (
         clk        => clk,
         bus_clk    => bus_clk,
         reset      => reset,
         -- Interface to CPU
         addr_check => addr_in(log2(MEM_DEPTH)-1 downto 0),
         data_out   => idata,
         hit        => ihit,
         -- Inteface to fill SM
         addr_fill  => filler_addr(log2(MEM_DEPTH)-1 downto 0),
         data_in    => data_out,
         wr         => iwr
      );
   
   DCACHE: cache
      Generic map (
         CACHE_DEPTH => DCACHE_DEPTH
      )
      Port map (
         clk        => clk,
         bus_clk    => bus_clk,
         reset      => reset,
         -- Interface to CPU
         addr_check => addr_in(log2(MEM_DEPTH)-1 downto 0),
         data_out   => ddata,
         hit        => dhit,
         -- Inteface to fill SM
         addr_fill  => filler_addr(log2(MEM_DEPTH)-1 downto 0),
         data_in    => data_out,
         wr         => dwr
      );
   
   CACHE_MULTIPLEXER: process(ihit, dhit, instr, wr_in, idata, filler_addr, ddata, data_out, done_in, addr_in)
   begin
      addr_out <= filler_addr;
      data_out <= (others => 'Z');
      smpause <= '0';
      
      if busy = '1' then
         if instr = '1' and ihit = '1' and wr_in = '0' then -- We get a IHIT
            data_in <= idata;
            done_out <= '1';
            report "cache_ctl.vhd: ICACHE_HIT" severity NOTE;
         elsif instr = '0' and dhit = '1' and wr_in = '0' then -- We get a DHIT
            data_in <= ddata;
            done_out <= '1';
            report "cache_ctl.vhd: DCACHE_HIT" severity NOTE;
         else -- Miss
            if wr_in = '1' then
               data_out <= data_in;
               data_in <= (others => 'Z');
            else
               data_in <= data_out;
               data_out <= (others => 'Z');
            end if;
            addr_out <= addr_in;
            done_out <= done_in;
            smpause <= '1';
            report "cache_ctl.vhd: CACHE MISS" severity NOTE;            
         end if;
      end if;
   end process;
   
   -- Write through mode
   wr_out <= wr_in;
   
   filler_addr <= start_addr + (cntr & "00");
   
   -- Cache statemachine with embedded counter
   SYNC_PROC: process(bus_clk, reset, next_state, cntr, addr_in, smpause, done_in)
   begin
      if rising_edge(bus_clk) then
         if reset = '1' then
            state <= IDLE;
            cntr <= (others => '0');
            start_addr <= (others => '0');
         else
            if state = IDLE and (next_state = IREAD or next_state = DREAD)  then
               cntr <= (others => '0');
               start_addr <= addr_in;
            end if;
            state <= next_state;
         end if;
      end if;
      
      if rising_edge(done_in) then
         if smpause = '0' then
            cntr <= cntr + 1;
         end if;
      end if;
   end process;
   
   OUTPUT_DECODE: process(state, done_in, smpause)
   begin
      iwr <= '0';
      dwr <= '0';
      case (state ) is
         when IREAD =>
            if smpause = '0' then
               iwr <= done_in;
            end if;
         when DREAD =>
            if smpause = '0' then
               dwr <= done_in;
            end if;
         when others =>
            
      end case;
  end process;
   
   NEXT_STATE_DECODE: process(state, ihit, dhit, instr, cntr)
   begin
      next_state <= state;
      case (state) is
         when IDLE =>
            -- If instr miss then put the block in ICACHE
            -- If data  miss then put the block in DCACHE
            if ihit = '0' and instr = '1' then
               next_state <= IREAD;
            elsif dhit = '0' and instr = '0' then
               next_state <= DREAD;
            end if;
         when IREAD =>
            if cntr > BLOCK_SIZE / WORD_SIZE then
               next_state <= IDLE;
            end if; 
         when DREAD => 
            if cntr > BLOCK_SIZE / WORD_SIZE then
               next_state <= IDLE;
            end if;
         when others =>
            report "cache_ctl.vhd: Error bad state" severity FAILURE;
      end case;
   end process;

end Behavioral;

