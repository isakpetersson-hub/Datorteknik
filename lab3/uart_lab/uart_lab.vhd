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
    signal counter : unsigned(13 downto 0);    -- transmission length counter

    signal bitcount : unsigned(3 downto 0) := X"0";

    signal clear : std_logic;       -- synchronous clear

begin

  clear <= btnC;
  -- *****************************
  -- *  synkroniseringsvippor    *
  -- *****************************
process(clk) begin
  if rising_edge(clk) then
    if clear = '1' then
      rx1 <= '1';
      rx2 <= '1';
    else
      rx1 <= RsRx;
      rx2 <= rx1;
    end if;
  end if;
end process;

  -- *****************************
  -- *       styrenhet           *
  -- *****************************
process(clk) begin
  if rising_edge(clk) then
    if clear = '1' then
      counter <= (others => '0');
      s1 <= '0';
      sp <= '0';
      lp <= '0';
    else

      sp <= '0';
      lp <= '0';

      -- Vänta på startbit
      if s1 = '0' then
        if rx2 = '0' then
          s1 <= '1';
          counter <= to_unsigned(434,14);
        end if;

      else
        if counter = 0 then
          sp <= '1';
          if bitcount = 9 then
            s1 <= '0';
            stop <= '1';
            bitcount <= (others => '0');
          else
            bitcount <= bitcount + 1;
          end if;          
          counter <= to_unsigned(868,14);
        else
          counter <= counter - 1;
        end if;
      end if;
      if stop = '1' then
        stop <= '0';
        lp <= '1';
      end if;
    end if;
  end if;
end process;

  -- *****************************
  -- * 10 bit skiftregister      *
  -- *****************************

  process(clk) begin
    if rising_edge(clk) then
      if clear = '1' then
        sreg <= B"0_00000000_0";
      elsif sp = '1' then
        sreg <= rx2 & sreg(9 downto 1);
      end if;
    end if;
  end process;
    -- *****************************
  -- * 2  bit register           *
  -- *****************************

  process(clk) begin
    if rising_edge(clk) then
      if clear = '1' then
        pos <= "00";
      elsif lp = '1' then
        if pos = "11" then
          pos <= "00";
        else
          pos <= pos + 1;
        end if;
      end if;
    end if;
  end process;

  -- *****************************
  -- * 16 bit register           *
  -- *****************************

  process(clk) begin
    if rising_edge(clk) then
      if clear = '1' then
        hex4 <= X"0000";
      elsif lp = '1' then

        case pos is
          when "00" =>
            hex4(15 downto 12) <= sreg(4 downto 1);
          when "01" =>
            hex4(11 downto 8)  <= sreg(4 downto 1);
          when "10" =>
            hex4(7 downto 4)   <= sreg(4 downto 1);
          when others =>
            hex4(3 downto 0)   <= sreg(4 downto 1);
        end case;

      end if;
    end if;
  end process;

  -- *****************************
  -- * Multiplexad display       *
  -- *****************************
  led: leddriver port map (clk=>clk, seg=>seg, dp=>dp, an=>an, hex4=>hex4);
end Behavioral;