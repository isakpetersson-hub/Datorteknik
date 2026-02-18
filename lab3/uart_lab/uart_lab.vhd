library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


entity uart_lab is
    Port ( clk  : in std_logic;     -- system clock
           btnC : in std_logic;     -- reset button
           RsRx : in std_logic;     -- UART RS2323 Rx
           seg  : out std_logic_vector(6 downto 0);   -- 7-seg, segments
           dp   : out std_logic;                      -- 7-seg, decimal point
           an : out std_logic_vector (3 downto 0));   -- 7-seg, anode
end uart_lab;

architecture behavioral of uart_lab is
    
  component leddriver
    Port ( clk  : in std_logic;     -- system clock
           seg  : out std_logic_vector(6 downto 0);   -- 7-seg, segments
           dp   : out std_logic;                      -- 7-seg, decimal point
           an : out std_logic_vector(3 downto 0);     -- 7-seg, anode
           hex4 : in std_logic_vector(15 downto 0));  -- four HEX-digits
    end component;

    signal sreg : std_logic_vector(9 downto 0) := B"0_00000000_0";  -- 10 bit shift register
    signal hex4 : std_logic_vector(15 downto 0) := X"0000";  
    signal rx1,rx2 : std_logic;     -- synchronizing flip-flops
    signal sp : std_logic;          -- shift pulse
    signal lp : std_logic;          -- load pulse
    signal pos : unsigned(1 downto 0);                -- HEX-digit position

    signal s1 : std_logic;          -- state of transmission
    signal start, stop : std_logic; -- start/stop transmission
    signal counter : unsigned(13 downto 0);           -- transmission length counter

    signal clear : std_logic;       -- synchronous clear

begin

  -- clear <= btnC;
  -- *****************************
  -- *  synkroniseringsvippor    *
  -- *****************************
  process(clk) begin
    if rising_edge(clk) then
      rx1 <= RsRx;
      rx2 <= rx1;
    end if;
  end process;

  -- *****************************
  -- *       styrenhet           *
  -- *****************************
  process(clk) begin
    if not rx1 and rx2 then
      start <= '1';
    end if;
    if start = '1' then 
      if rising_edge(clk) then
        sp <= '0';
        if counter = '8' then
          lp <= '1';
          counter <= '0';
          start <= '0';
        end if;
        counter <= counter+1;
      end if;
      if falling_edge(clk) then
        sp <= '1';      end if;

  -- *****************************
  -- * 10 bit skiftregister      *
  -- *****************************

  process(clk) begin
    if sp = '1' then 
      shift sreg;
      sreg <= rx2;
    end if;
  end process;

  -- *****************************
  -- * 2  bit register           *
  -- *****************************



  -- *****************************
  -- * 16 bit register           *
  -- *****************************



  -- *****************************
  -- * Multiplexad display       *
  -- *****************************
  led: leddriver port map (clk=>clk, seg=>seg, dp=>dp, an=>an, hex4=>hex4);
end Behavioral;

