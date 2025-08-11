library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_UARTUnit is
  Port (
    tb_error : out std_logic
  );
end TB_UARTUnit;

architecture TESTBENCH of TB_UARTUnit is
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
    signal tb_clk, tb_rst : STD_LOGIC;
    signal tb_send_data : std_logic_vector(7 downto 0);
    signal tb_write_en : std_logic;
    signal tb_full, tb_exp_full : std_logic;
    signal tb_TX_pin, tb_exp_TX_pin : std_logic;
        
    signal tb_received_data, tb_exp_received_data : std_logic_vector(7 downto 0);
    signal tb_frame_error, tb_exp_frame_error : std_logic;
    signal tb_parity_error, tb_exp_parity_error : std_logic;
    signal tb_new_data_received, tb_exp_new_data_received : std_logic;
    signal tb_RX_pin : std_logic;
    constant tbase : time := 100 ns;
begin
  COMP: UART_Unit generic map(10000000, 1000000, 8, 1, 1, 0) port map(tb_clk, tb_rst, tb_send_data, tb_write_en, tb_full, tb_TX_Pin, tb_received_data, tb_frame_error, tb_parity_error, tb_new_data_received, tb_RX_pin);
    
  -- 10 MHz
  CLOCK: process
  begin
    for i in 5000 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;
    
  tb_rst <= '1', '0' after 2*tbase;

  -- TRANSMIT:

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 14*tbase, '0' after 15*tbase, -- should be skipped
    '1' after 20*tbase, '0' after 21*tbase;

  tb_send_data <= "00000000",
    "11001110" after 10*tbase, "00000000" after 11*tbase,
    "11110000" after 15*tbase, "00000000" after 16*tbase, -- should be skipped
    "10101010" after 20*tbase, "00000000" after 21*tbase;

  tb_exp_full <= 'U', '0' after 1*tbase,
    '1' after 10*tbase, '0' after 17*tbase,
    '1' after 20*tbase, '0' after 127*tbase;

  tb_exp_TX_pin <= 'U', '1' after 1*tbase,
    '0' after 26*tbase, '0' after 36*tbase, '1' after 46*tbase, '1' after 56*tbase, '1' after 66*tbase, '0' after 76*tbase, '0' after 86*tbase, '1' after 96*tbase, '1' after 106*tbase, '1' after 116*tbase, '1' after 126*tbase,
    '0' after 136*tbase, '0' after 146*tbase, '1' after 156*tbase, '0' after 166*tbase, '1' after 176*tbase, '0' after 186*tbase, '1' after 196*tbase, '0' after 206*tbase, '1' after 216*tbase, '0' after 226*tbase, '1' after 236*tbase;

  -- RECEIVE:

  tb_RX_pin <= '1',
    '0' after 25*tbase, '1' after 35*tbase, '1' after 45*tbase, '1' after 55*tbase, '1' after 65*tbase, '0' after 75*tbase, '0' after 85*tbase, '1' after 95*tbase, '1' after 105*tbase, '0' after 115*tbase, '1' after 125*tbase, -- 0xCF
    '0' after 135*tbase, '1' after 145*tbase, '1' after 155*tbase, '0' after 165*tbase, '1' after 175*tbase, '0' after 185*tbase, '1' after 195*tbase, '0' after 205*tbase, '1' after 215*tbase, '1' after 225*tbase, '1' after 235*tbase, -- 0xAB
    '0' after 1025*tbase, '1' after 1035*tbase, '1' after 1045*tbase, '1' after 1055*tbase, '1' after 1065*tbase, '0' after 1075*tbase, '0' after 1085*tbase, '1' after 1095*tbase, '1' after 1105*tbase, '1' after 1115*tbase, '1' after 1125*tbase, -- 0xCF (PARITY ERROR)
    '0' after 1135*tbase, '1' after 1145*tbase, '1' after 1155*tbase, '0' after 1165*tbase, '1' after 1175*tbase, '0' after 1185*tbase, '1' after 1195*tbase, '0' after 1205*tbase, '0' after 1215*tbase, '0' after 1225*tbase, '1' after 1245*tbase, -- 0x2B (FRAME ERROR)
    '0' after 2025*tbase, '1' after 2035*tbase, '1' after 2045*tbase, '1' after 2055*tbase, '1' after 2065*tbase, '0' after 2075*tbase, '0' after 2085*tbase, '1' after 2095*tbase, '1' after 2105*tbase, '0' after 2115*tbase, '1' after 2125*tbase, -- 0xCF
    '0' after 2135*tbase, '1' after 2145*tbase, '1' after 2155*tbase, '0' after 2165*tbase, '1' after 2175*tbase, '0' after 2185*tbase, '1' after 2195*tbase, '0' after 2205*tbase, '1' after 2215*tbase, '1' after 2225*tbase, '1' after 2235*tbase; -- 0xAB

  -- is high as long as idle because reset is pulled
  tb_exp_new_data_received <= 'U', '0' after 1*tbase,
    '1' after 131*tbase, '0' after 134*tbase,
    '1' after 241*tbase, '0' after 244*tbase,
    '1' after 1131*tbase, '0' after 1134*tbase,
    '1' after 1241*tbase, '0' after 1248*tbase,
    '1' after 2131*tbase, '0' after 2134*tbase,
    '1' after 2241*tbase, '0' after 2244*tbase;

  tb_exp_received_data <= "UUUUUUUU", "00000000" after 1*tbase,
    x"CF" after 131*tbase,
    x"AB" after 241*tbase,
    x"CF" after 1131*tbase,
    x"2B" after 1241*tbase,
    x"CF" after 2131*tbase,
    x"AB" after 2241*tbase;

  tb_exp_frame_error <= 'U', '0' after 1*tbase,
    '1' after 1241*tbase, '0' after 2131*tbase;

  tb_exp_parity_error <= 'U', '0' after 1*tbase,
    '1' after 1131*tbase, '0' after 1241*tbase;

  tb_error <= '0' when
    (tb_exp_new_data_received = tb_new_data_received) 
    and (tb_exp_frame_error = tb_frame_error) 
    and (tb_exp_full = tb_full) 
    and (tb_exp_parity_error = tb_parity_error) 
    and (tb_exp_received_data = tb_received_data) 
    and (tb_exp_TX_pin = tb_TX_pin) else '1';

end TESTBENCH;
