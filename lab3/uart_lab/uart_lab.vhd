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

  clear <= btnC;
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
  --dubbelkolla sensitivity listen kan vara cooked
  process(clk, rx1, rx2, start) begin
    if (rx1 = '0') and (rx2 = '1') then
      start <= '1';
    end if;
    if start = '1' then 
      if rising_edge(clk) then
        sp <= '0';
        counter <= counter+1;
        if counter = "00001101100100" then
          lp <= '1';
          counter <= "00000000000000";
          start <= '0';
        end if;
        if counter = "00000110110010" then
          sp <= '1';
        end if;
      end if;
    end if;
  end process;

  -- *****************************
  -- * 10 bit skiftregister      *
  -- *****************************

  process(sp, rx2, sreg) begin
    if sp = '1' then 
      sreg <= rx2 & sreg(9 downto 1);        --shift_left(sreg, rx2);
    end if;
  end process;

  -- *****************************
  -- * 2  bit register           *
  -- *****************************

process(lp) begin
  if pos = "11" then
    pos <= "00";
  else 
    pos <= pos+1;
  end if;
end process; 

  -- *****************************
  -- * 16 bit register           *
  -- *****************************

process(lp) begin
  if pos = "00" then
    hex4(15 downto 12) <= sreg(3 downto 0);
  elsif pos = "01" then
    hex4(11 downto 8) <= sreg(3 downto 0);
  elsif pos = "10" then
    hex4(7 downto 4) <= sreg(3 downto 0);
  elsif pos = "11" then
    hex4(3 downto 0) <= sreg(3 downto 0);
  end if;
end process; 

  -- *****************************
  -- * Multiplexad display       *
  -- *****************************
  led: leddriver port map (clk=>clk, seg=>seg, dp=>dp, an=>an, hex4=>hex4);
end Behavioral;