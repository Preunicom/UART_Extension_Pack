library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Main_Unit is
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
  signal tb_error : std_logic;
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

  tb_rst <= '1', '0' after 1*tbase;

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
    '0' after 335*tbase, '1' after 345*tbase, '0' after 355*tbase, '0' after 365*tbase, '0' after 375*tbase, '0' after 385*tbase, '0' after 395*tbase, '0' after 405*tbase, '0' after 415*tbase, '1' after 425*tbase, '1' after 435*tbase, --0b00000001 (get GPIO data - unit) (0x01)
    '0' after 445*tbase, '0' after 455*tbase, '0' after 465*tbase, '0' after 475*tbase, '0' after 485*tbase, '0' after 495*tbase, '0' after 505*tbase, '0' after 515*tbase, '0' after 525*tbase, '0' after 535*tbase, '1' after 545*tbase, --0b00000000 (get GPIO data - data) (0x00)
    '0' after 555*tbase, '0' after 565*tbase, '0' after 575*tbase, '0' after 585*tbase, '0' after 595*tbase, '0' after 605*tbase, '0' after 615*tbase, '0' after 625*tbase, '0' after 635*tbase, '0' after 645*tbase, '1' after 655*tbase, --0b00000000 (UART in - unit) (0x00)
    '0' after 665*tbase, '0' after 675*tbase, '0' after 685*tbase, '0' after 695*tbase, '0' after 705*tbase, '1' after 715*tbase, '0' after 725*tbase, '0' after 735*tbase, '0' after 745*tbase, '1' after 755*tbase, '1' after 765*tbase, --0b00010000 (UART in - data) (0x10)
    '0' after 775*tbase, '1' after 785*tbase, '0' after 795*tbase, '0' after 805*tbase, '0' after 815*tbase, '0' after 825*tbase, '0' after 835*tbase, '0' after 845*tbase, '0' after 855*tbase, '1' after 865*tbase, '1' after 875*tbase, --0b00000001 (GPIO interrupt - unit) (0x01)
    '0' after 885*tbase, '1' after 895*tbase, '0' after 905*tbase, '0' after 915*tbase, '0' after 925*tbase, '0' after 935*tbase, '0' after 945*tbase, '0' after 955*tbase, '0' after 965*tbase, '1' after 975*tbase, '1' after 985*tbase, --0b00000000 (GPIO interrupt - data) (0x01)
    '0' after 1115*tbase, '1' after 1125*tbase, '0' after 1135*tbase, '0' after 1145*tbase, '0' after 1155*tbase, '0' after 1165*tbase, '0' after 1175*tbase, '0' after 1185*tbase, '0' after 1195*tbase, '1' after 1205*tbase, '1' after 1215*tbase, --0b00000001 (GPIO interrupt - unit) (0x01)
    '0' after 1225*tbase, '0' after 1235*tbase, '0' after 1245*tbase, '0' after 1255*tbase, '0' after 1265*tbase, '0' after 1275*tbase, '0' after 1285*tbase, '0' after 1295*tbase, '0' after 1305*tbase, '0' after 1315*tbase, '1' after 1325*tbase, --0b00000000 (GPIO interrupt - data) (0x00)
    '0' after 3115*tbase, '0' after 3125*tbase, '1' after 3135*tbase, '0' after 3145*tbase, '0' after 3155*tbase, '0' after 3165*tbase, '0' after 3175*tbase, '0' after 3185*tbase, '0' after 3195*tbase, '1' after 3205*tbase, '1' after 3215*tbase, --0b00000010 (Timer interrupt - unit) (0x02)
    '0' after 3225*tbase, '1' after 3235*tbase, '1' after 3245*tbase, '1' after 3255*tbase, '1' after 3265*tbase, '1' after 3275*tbase, '1' after 3285*tbase, '1' after 3295*tbase, '1' after 3305*tbase, '0' after 3315*tbase, '1' after 3325*tbase; --0b11111111 (Timer interrupt - data) (0xFF)

  tb_exp_tx_pin_a <= '1',
    '0' after 1180*tbase, '1' after 1220*tbase, '0' after 1260*tbase, '1' after 1300*tbase, '1' after 1340*tbase, '1' after 1380*tbase, '1' after 1420*tbase, '1' after 1460*tbase, '0' after 1500*tbase, '1' after 1540*tbase, --0b01111101 (0x7D)
    '0' after 1580*tbase, '1' after 1620*tbase, '0' after 1660*tbase, '0' after 1700*tbase, '0' after 1740*tbase, '1' after 1780*tbase, '0' after 1820*tbase, '1' after 1860*tbase, '0' after 1900*tbase, '1' after 1940*tbase; --0b01010001 (0x51)

  tb_exp_gpio_pins_out <= "00",
    "10" after 719*tbase;

    tb_error <= '0' when 
    (tb_exp_tx_pin_host = tb_tx_pin_host)
    and (tb_exp_tx_pin_a = tb_tx_pin_a)
    and (tb_exp_gpio_pins_out = tb_gpio_pins_out) else '1';

end TESTBENCH;