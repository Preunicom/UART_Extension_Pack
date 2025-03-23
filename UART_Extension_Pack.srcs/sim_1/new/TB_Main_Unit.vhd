library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Main_Unit is
  Port(
    signal tb_error : out std_logic
  );
end TB_Main_Unit;

architecture TESTBENCH of TB_Main_Unit is
  component Main_Unit
    Generic(
      -- FPGA_FREQ has to be minimum 2*HOST_BAUD
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000;
      -- HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15 has to be fullfilled
      -- HOST_DATA_BITS >= 8 has to be fullfilled
      HOST_DATA_BITS : integer := 8;
      HOST_STOP_BITS : integer := 1;
      HOST_PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      HOST_PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      tx_pin_host : out std_logic;
      rx_pin_host : in std_logic;
      ----------------- UNIT PORTS -----------------
      tx_pin_a : out std_logic;
      rx_pin_a : in std_logic;
      gpio_pins_in : in STD_LOGIC_VECTOR (0 downto 0);
      gpio_pins_out : out STD_LOGIC_VECTOR (1 downto 0)
      
      --------------- UNIT PORTS END ---------------
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  
  signal tb_tx_pin_host, tb_exp_tx_pin_host : STD_LOGIC;
  signal tb_tx_pin_a, tb_exp_tx_pin_a : STD_LOGIC;
  signal tb_rx_pin_host : STD_LOGIC;
  signal tb_rx_pin_a : std_logic;
  signal tb_gpio_pins_in : std_logic_vector(0 downto 0);
  signal tb_gpio_pins_out, tb_exp_gpio_pins_out : std_logic_vector(1 downto 0);

  constant tbase : time := 100 ns;
begin
  MU: Main_Unit generic map(10000000, 1000000, 8, 1, 1, 0) port map(tb_clk, tb_rst, tb_tx_pin_host, tb_rx_pin_host, tb_tx_pin_a, tb_rx_pin_a, tb_gpio_pins_in, tb_gpio_pins_out);
  
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

  tb_rx_pin_host <= '1',
    '0' after 10*tbase, '1' after 20*tbase, '0' after 30*tbase, '0' after 40*tbase, '0' after 50*tbase, '0' after 60*tbase, '0' after 70*tbase, '1' after 80*tbase, '0' after 90*tbase, '0' after 100*tbase, '1' after 110*tbase, --0b01000001 (get GPIO data) (0x41)
    '0' after 210*tbase, '1' after 220*tbase, '1' after 230*tbase, '1' after 240*tbase, '1' after 250*tbase, '1' after 260*tbase, '1' after 270*tbase, '1' after 280*tbase, '1' after 290*tbase, '0' after 300*tbase, '1' after 310*tbase, --0b11111111 (0xFF)
    '0' after 410*tbase, '1' after 420*tbase, '0' after 430*tbase, '0' after 440*tbase, '0' after 450*tbase, '0' after 460*tbase, '0' after 470*tbase, '0' after 480*tbase, '0' after 490*tbase, '1' after 500*tbase, '1' after 510*tbase, --00000001 (set GPIO data) (0x01)
    '0' after 610*tbase, '0' after 620*tbase, '1' after 630*tbase, '1' after 640*tbase, '1' after 650*tbase, '1' after 660*tbase, '1' after 670*tbase, '1' after 680*tbase, '1' after 690*tbase, '1' after 700*tbase, '1' after 710*tbase, --0b11111110 (0xFE)
    '0' after 810*tbase, '0' after 820*tbase, '0' after 830*tbase, '0' after 840*tbase, '0' after 850*tbase, '0' after 860*tbase, '0' after 870*tbase, '0' after 880*tbase, '0' after 890*tbase, '0' after 900*tbase, '1' after 910*tbase, --00000000 (send UART) (0x00)
    '0' after 1010*tbase, '1' after 1020*tbase, '0' after 1030*tbase, '1' after 1040*tbase, '1' after 1050*tbase, '1' after 1060*tbase, '1' after 1070*tbase, '1' after 1080*tbase, '0' after 1090*tbase, '0' after 1100*tbase, '1' after 1110*tbase, --0b01111101 (0x7D)
    '0' after 1210*tbase, '0' after 1220*tbase, '0' after 1230*tbase, '0' after 1240*tbase, '0' after 1250*tbase, '0' after 1260*tbase, '0' after 1270*tbase, '0' after 1280*tbase, '0' after 1290*tbase, '0' after 1300*tbase, '1' after 1310*tbase, --00000000 (send UART) (0x00)
    '0' after 1410*tbase, '1' after 1420*tbase, '0' after 1430*tbase, '0' after 1440*tbase, '0' after 1450*tbase, '1' after 1460*tbase, '0' after 1470*tbase, '1' after 1480*tbase, '0' after 1490*tbase, '1' after 1500*tbase, '1' after 1510*tbase, --0b01010001 (0x51)
    '0' after 1610*tbase, '0' after 1620*tbase, '1' after 1630*tbase, '0' after 1640*tbase, '0' after 1650*tbase, '0' after 1660*tbase, '0' after 1670*tbase, '1' after 1680*tbase, '1' after 1690*tbase, '1' after 1700*tbase, '1' after 1710*tbase, --11000010 (set start value Timer) (0xC2)
    '0' after 1810*tbase, '0' after 1820*tbase, '0' after 1830*tbase, '1' after 1840*tbase, '1' after 1850*tbase, '1' after 1860*tbase, '1' after 1870*tbase, '1' after 1880*tbase, '1' after 1890*tbase, '0' after 1900*tbase, '1' after 1910*tbase, --0b11111100 (0xFC)
    '0' after 2010*tbase, '0' after 2020*tbase, '1' after 2030*tbase, '0' after 2040*tbase, '0' after 2050*tbase, '0' after 2060*tbase, '0' after 2070*tbase, '1' after 2080*tbase, '0' after 2090*tbase, '0' after 2100*tbase, '1' after 2110*tbase, --01000010 (restart Timer) (0x02)
    '0' after 2210*tbase, '1' after 2220*tbase, '1' after 2230*tbase, '1' after 2240*tbase, '1' after 2250*tbase, '1' after 2260*tbase, '1' after 2270*tbase, '1' after 2280*tbase, '1' after 2290*tbase, '0' after 2300*tbase, '1' after 2310*tbase, --0b11111111 (0xFF)
    '0' after 2410*tbase, '0' after 2420*tbase, '1' after 2430*tbase, '0' after 2440*tbase, '0' after 2450*tbase, '0' after 2460*tbase, '0' after 2470*tbase, '0' after 2480*tbase, '0' after 6490*tbase, '1' after 2500*tbase, '1' after 2510*tbase, --00000010 (enable Timer) (0x02)
    '0' after 2610*tbase, '1' after 2620*tbase, '1' after 2630*tbase, '1' after 2640*tbase, '1' after 2650*tbase, '1' after 2660*tbase, '1' after 2670*tbase, '1' after 2680*tbase, '1' after 2690*tbase, '0' after 2700*tbase, '1' after 2710*tbase, --0b11111111 (0xFF)  
    '0' after 3200*tbase, '0' after 3210*tbase, '1' after 3220*tbase, '0' after 3230*tbase, '0' after 3240*tbase, '0' after 3250*tbase, '0' after 3260*tbase, '0' after 3270*tbase, '0' after 3280*tbase, '1' after 3290*tbase, '1' after 3300*tbase, --00000010 (disable Timer) (0x02)
    '0' after 3400*tbase, '0' after 3410*tbase, '0' after 3420*tbase, '0' after 3430*tbase, '0' after 3440*tbase, '0' after 3450*tbase, '0' after 3460*tbase, '0' after 3470*tbase, '0' after 3480*tbase, '0' after 3490*tbase, '1' after 3500*tbase; --0b00000000 (0x00)
  
  tb_rx_pin_a <= '1',
    '0' after 100*tbase, '0' after 140*tbase, '0' after 180*tbase, '0' after 220*tbase, '0' after 260*tbase, '1' after 300*tbase, '0' after 340*tbase, '0' after 380*tbase, '0' after 420*tbase, '1' after 460*tbase; --0b00010000

  tb_gpio_pins_in <= "0",
    "1" after 500*tbase,
    "0" after 1100*tbase;

  tb_exp_tx_pin_host <= '1',
    '0' after 336*tbase, '1' after 346*tbase, '0' after 356*tbase, '0' after 366*tbase, '0' after 376*tbase, '0' after 386*tbase, '0' after 396*tbase, '0' after 406*tbase, '0' after 416*tbase, '1' after 426*tbase, '1' after 436*tbase, --0b00000001 (get GPIO data - unit) (0x01)
    '0' after 446*tbase, '0' after 456*tbase, '0' after 466*tbase, '0' after 476*tbase, '0' after 486*tbase, '0' after 496*tbase, '0' after 506*tbase, '0' after 516*tbase, '0' after 526*tbase, '0' after 536*tbase, '1' after 546*tbase, --0b00000000 (get GPIO data - data) (0x00)
    '0' after 556*tbase, '0' after 566*tbase, '0' after 576*tbase, '0' after 586*tbase, '0' after 596*tbase, '0' after 606*tbase, '0' after 616*tbase, '0' after 626*tbase, '0' after 636*tbase, '0' after 646*tbase, '1' after 656*tbase, --0b00000000 (UART in - unit) (0x00)
    '0' after 666*tbase, '0' after 676*tbase, '0' after 686*tbase, '0' after 696*tbase, '0' after 706*tbase, '1' after 716*tbase, '0' after 726*tbase, '0' after 736*tbase, '0' after 746*tbase, '1' after 756*tbase, '1' after 766*tbase, --0b00010000 (UART in - data) (0x10)
    '0' after 776*tbase, '1' after 786*tbase, '0' after 796*tbase, '0' after 806*tbase, '0' after 816*tbase, '0' after 826*tbase, '0' after 836*tbase, '0' after 846*tbase, '0' after 856*tbase, '1' after 866*tbase, '1' after 876*tbase, --0b00000001 (GPIO interrupt - unit) (0x01)
    '0' after 886*tbase, '1' after 896*tbase, '0' after 906*tbase, '0' after 916*tbase, '0' after 926*tbase, '0' after 936*tbase, '0' after 946*tbase, '0' after 956*tbase, '0' after 966*tbase, '1' after 976*tbase, '1' after 986*tbase, --0b00000000 (GPIO interrupt - data) (0x01)
    '0' after 1116*tbase, '1' after 1126*tbase, '0' after 1136*tbase, '0' after 1146*tbase, '0' after 1156*tbase, '0' after 1166*tbase, '0' after 1176*tbase, '0' after 1186*tbase, '0' after 1196*tbase, '1' after 1206*tbase, '1' after 1216*tbase, --0b00000001 (GPIO interrupt - unit) (0x01)
    '0' after 1226*tbase, '0' after 1236*tbase, '0' after 1246*tbase, '0' after 1256*tbase, '0' after 1266*tbase, '0' after 1276*tbase, '0' after 1286*tbase, '0' after 1296*tbase, '0' after 1306*tbase, '0' after 1316*tbase, '1' after 1326*tbase, --0b00000000 (GPIO interrupt - data) (0x00)
    '0' after 3116*tbase, '0' after 3126*tbase, '1' after 3136*tbase, '0' after 3146*tbase, '0' after 3156*tbase, '0' after 3166*tbase, '0' after 3176*tbase, '0' after 3186*tbase, '0' after 3196*tbase, '1' after 3206*tbase, '1' after 3216*tbase, --0b00000010 (Timer interrupt - unit) (0x02)
    '0' after 3226*tbase, '1' after 3236*tbase, '1' after 3246*tbase, '1' after 3256*tbase, '1' after 3266*tbase, '1' after 3276*tbase, '1' after 3286*tbase, '1' after 3296*tbase, '1' after 3306*tbase, '0' after 3316*tbase, '1' after 3326*tbase; --0b11111111 (Timer interrupt - data) (0xFF)

  tb_exp_tx_pin_a <= '1',
    '0' after 1181*tbase, '1' after 1221*tbase, '0' after 1261*tbase, '1' after 1301*tbase, '1' after 1341*tbase, '1' after 1381*tbase, '1' after 1421*tbase, '1' after 1461*tbase, '0' after 1501*tbase, '1' after 1541*tbase, --0b01111101 (0x7D)
    '0' after 1581*tbase, '1' after 1621*tbase, '0' after 1661*tbase, '0' after 1701*tbase, '0' after 1741*tbase, '1' after 1781*tbase, '0' after 1821*tbase, '1' after 1861*tbase, '0' after 1901*tbase, '1' after 1941*tbase; --0b01010001 (0x51)

  tb_exp_gpio_pins_out <= "UU", "00" after 1*tbase,
    "10" after 719*tbase;

    tb_error <= '0' when 
    (tb_exp_tx_pin_host = tb_tx_pin_host)
    and (tb_exp_tx_pin_a = tb_tx_pin_a)
    and (tb_exp_gpio_pins_out = tb_gpio_pins_out) else '1';

end TESTBENCH;