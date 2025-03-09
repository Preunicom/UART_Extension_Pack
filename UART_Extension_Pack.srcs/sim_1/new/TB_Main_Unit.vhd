library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Main_Unit is
end TB_Main_Unit;

architecture TESTBENCH of TB_Main_Unit is
  component Main_Unit
  Generic(
    HOST_BAUD : integer := 1000000;
    FPGA_FREQ : integer := 12000000
  );
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    tx_pin_host, tx_pin_a : out std_logic;
    rx_pin_host, rx_pin_a : in std_logic;
    gpio_pins_in : in STD_LOGIC_VECTOR (7 downto 0);
    gpio_pins_out : out STD_LOGIC_VECTOR (7 downto 0)
  );
  end component;
  constant tbase: time := 10 ns;
  signal tb_clk, tb_rst, tb_tx_pin_host, tb_tx_pin_a, tb_rx_pin_host, tb_rx_pin_a : std_logic;
  signal tb_gpio_pins_in, tb_gpio_pins_out : std_logic_vector(7 downto 0);
begin
  MU: Main_Unit generic map(50000000, 100000000) port map(tb_clk, tb_rst, tb_tx_pin_host, tb_tx_pin_a, tb_rx_pin_host, tb_rx_pin_a, tb_gpio_pins_in, tb_gpio_pins_out);
  
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
  tb_rx_pin_host <= '1',
                    '0' after 10*tbase, '1' after 12*tbase, '0' after 14*tbase, '1' after 18*tbase, '0' after 20*tbase, '1' after 28*tbase, --0b00001001 (get GPIO data)
                    '0' after 40*tbase, '1' after 42*tbase, --0b11111111
                    '0' after 110*tbase, '1' after 112*tbase, '0' after 114*tbase, '1' after 128*tbase, --00000001 (set GPIO data)
                    '0' after 140*tbase, '1' after 144*tbase, --0b11111110
                    '0' after 200*tbase, '1' after 218*tbase, --00000000 (send UART)
                    '0' after 240*tbase,  '1' after 246*tbase, --0b11111100
                    '0' after 300*tbase, '1' after 318*tbase, --00000000 (send UART)
                    '0' after 340*tbase,  '1' after 350*tbase; --0b11110000
  tb_rx_pin_a <= '1',
                 '0' after 110*tbase, '1' after 120*tbase, '0' after 122*tbase, '1' after 128*tbase; --0b00010000
  tb_gpio_pins_in <= "01111111", --0x01
                     "11010011" after 50*tbase, --0xD3
                     "00001111" after 100*tbase; --0xF0

end TESTBENCH;