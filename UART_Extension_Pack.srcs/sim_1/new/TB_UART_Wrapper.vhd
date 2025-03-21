library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_UART_Wrapper is
end TB_UART_Wrapper;

architecture Behavioral of TB_UART_Wrapper is
  component UART_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN_FREQ_HZ has to be minimum 2*BAUD_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      -- DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); -- unused
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(HOST_DATA_BITS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      TX_pin : out std_logic;
      RX_pin : in std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en : std_logic;
  signal tb_access_mode : std_logic_vector(1 downto 0); --*0: set, *1: get
  signal tb_unit_data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done : std_logic;
  signal tb_TX_pin, tb_exp_TX_pin : std_logic;
  signal tb_RX_pin : std_logic;

  constant tbase : time := 100 ns;
  signal tb_error : std_logic;
begin
  COMP: UART_Wrapper generic map(8, 10000000, 1000000, 8, 1, 0, 0) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_TX_pin, tb_RX_pin);

  -- 10 MHz
  CLOCK: process
  begin
    for i in 1000 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 1*tbase;

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 100*tbase, '0' after 101*tbase;

  tb_access_mode <= "00";

  tb_unit_data_in <= "00000000",
    "11000011" after 10*tbase, -- 0xC3
    "11001111" after 100*tbase; -- 0xCF

  tb_scheduler_done <= '0',
    '1' after 120.5*tbase, '0' after 122*tbase,
    '1' after 300.5*tbase, '0' after 302*tbase;

  tb_RX_pin <= '1',
    '0' after 5*tbase,
    '1' after 15*tbase,
    '0' after 45*tbase,
    '1' after 85*tbase, -- END 0x87
    '0' after 150*tbase,
    '1' after 160*tbase, -- END 0xFF
    '0' after 300*tbase,
    '1' after 400*tbase; -- END FRAME ERROR

  tb_exp_unit_data_out <= "00000000", 
    "10000111" after 101*tbase,
    "11111111" after 246*tbase,
    "00000000" after 396*tbase;

  tb_exp_scheduler_wanted <= '0',
    '1' after 101*tbase, '0' after 120.5*tbase,
    '1' after 246*tbase, '0' after 300.5*tbase;

  tb_exp_TX_pin <= '1',
    '0' after 105*tbase,
    '1' after 115*tbase,
    '0' after 135*tbase,
    '1' after 175*tbase, -- END 0xC3
    '0' after 205*tbase,
    '1' after 215*tbase,
    '0' after 255*tbase,
    '1' after 275*tbase; -- END 0xCF
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_TX_pin = tb_TX_pin) else '1';




end Behavioral;
