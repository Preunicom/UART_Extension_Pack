
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Encoder is
end TB_Encoder;

architecture TESTBENCH of TB_Encoder is
  component Encoder
    Generic (
      DATA_BITS : integer := 8
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      write_en : in std_logic;
      uart_is_empty : in std_logic;
      unit_number : in std_logic_vector(2 downto 0); 
      unit_data : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_out : out std_logic_vector(DATA_BITS-1 downto 0);
      uart_out_valid : out std_logic
    );
  end component;
  component UART_Unit
    Generic (
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      -- DATA_BITS + STOP_BITS <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      send_data : in std_logic_vector(DATA_BITS-1 downto 0);
      write_en : in std_logic;
      full : out std_logic;
      TX_pin : out std_logic;

      received_data : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error, parity_error : out std_logic;
      new_data_received : out std_logic;
      RX_pin : in std_logic
    );
  end component;
  -- In
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_write_en : std_logic;
  signal tb_unit_number : std_logic_vector(2 downto 0); 
  signal tb_uart_is_empty : std_logic;
  signal tb_unit_data : std_logic_vector(8-1 downto 0);
  -- Out
  signal tb_uart_out : std_logic_vector(8-1 downto 0);
  signal tb_uart_out_valid : std_logic;
  -- UART
  signal tb_TX_pin : std_logic;
  constant tbase: time := 10 ns;
begin
  DOM: Encoder generic map(8) port map(tb_clk, tb_rst, tb_write_en, not tb_uart_is_empty, tb_unit_number, tb_unit_data, tb_uart_out, tb_uart_out_valid);
  UART: UART_Unit generic map(100000000, 50000000) port map(tb_clk, tb_rst, tb_uart_out, tb_uart_out_valid, tb_uart_is_empty, tb_TX_pin, open, open, open, open, '0');
    
  CLK: process
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
  tb_write_en <= '1', '0' after 2*tbase, '1' after 100*tbase, '0' after 101*tbase;
  tb_unit_number <= "010", "111" after 100*tbase;
  tb_unit_data <= "11110000", "00001111" after 100*tbase;
  
end TESTBENCH;
