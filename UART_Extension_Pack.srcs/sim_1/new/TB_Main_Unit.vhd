library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Main_Unit is
  Port(
    signal tb_error : out std_logic
  );
end TB_Main_Unit;

-- Testbench for 5 fully used Units:
-- U0: Reset --> generic map(HOST_DATA_BITS)
-- U1: Error --> generic map(HOST_DATA_BITS)
-- U2: UART --> generic map(HOST_DATA_BITS, FPGA_FREQ, 250000, 8, 1, 0, 0)
-- U3: GPIO --> generic map(HOST_DATA_BITS, 1, 2)
-- U4: Timer --> generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD)
-- U5: SPI --> generic map(HOST_DATA_BITS, FPGA_FREQ, 9600, 1, 0, 0, 8)
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
      gpio_pins_out : out STD_LOGIC_VECTOR (1 downto 0);
      spi_sck : out std_logic;
      spi_cs : out std_logic_vector(0 downto 0);
      spi_mosi : out std_logic;
      spi_miso : in std_logic
      
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
  signal tb_spi_sck, tb_exp_spi_sck : std_logic;
  signal tb_spi_cs, tb_exp_spi_cs : std_logic_vector(0 downto 0);
  signal tb_spi_mosi, tb_exp_spi_mosi : std_logic;
  signal tb_spi_miso : std_logic;

  constant tbase : time := 100 ns;
begin
  MU: Main_Unit generic map(10000000, 1000000, 8, 1, 1, 0) port map(tb_clk, tb_rst, tb_tx_pin_host, tb_rx_pin_host, tb_tx_pin_a, tb_rx_pin_a, tb_gpio_pins_in, tb_gpio_pins_out, tb_spi_sck, tb_spi_cs, tb_spi_mosi, tb_spi_miso);
  
  -- 10 MHz
  CLOCK: process
  begin
    for i in 20000 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_rx_pin_host <= '1',
    '0' after 10*tbase, '1' after 20*tbase, '1' after 30*tbase, '0' after 40*tbase, '0' after 50*tbase, '0' after 60*tbase, '0' after 70*tbase, '1' after 80*tbase, '0' after 90*tbase, '1' after 100*tbase, '1' after 110*tbase, --0b01000011 (get GPIO data) (0x41)
    '0' after 210*tbase, '1' after 220*tbase, '1' after 230*tbase, '1' after 240*tbase, '1' after 250*tbase, '1' after 260*tbase, '1' after 270*tbase, '1' after 280*tbase, '1' after 290*tbase, '0' after 300*tbase, '1' after 310*tbase, --0b11111111 (0xFF)
    '0' after 410*tbase, '1' after 420*tbase, '1' after 430*tbase, '0' after 440*tbase, '0' after 450*tbase, '0' after 460*tbase, '0' after 470*tbase, '0' after 480*tbase, '0' after 490*tbase, '0' after 500*tbase, '1' after 510*tbase, --00000011 (set GPIO data) (0x01)
    '0' after 610*tbase, '0' after 620*tbase, '1' after 630*tbase, '1' after 640*tbase, '1' after 650*tbase, '1' after 660*tbase, '1' after 670*tbase, '1' after 680*tbase, '1' after 690*tbase, '1' after 700*tbase, '1' after 710*tbase, --0b11111110 (0xFE)
    '0' after 810*tbase, '0' after 820*tbase, '1' after 830*tbase, '0' after 840*tbase, '0' after 850*tbase, '0' after 860*tbase, '0' after 870*tbase, '0' after 880*tbase, '0' after 890*tbase, '1' after 900*tbase, '1' after 910*tbase, --00000010 (send UART) (0x00)
    '0' after 1010*tbase, '1' after 1020*tbase, '0' after 1030*tbase, '1' after 1040*tbase, '1' after 1050*tbase, '1' after 1060*tbase, '1' after 1070*tbase, '1' after 1080*tbase, '0' after 1090*tbase, '0' after 1100*tbase, '1' after 1110*tbase, --0b01111101 (0x7D)
    '0' after 1210*tbase, '0' after 1220*tbase, '1' after 1230*tbase, '0' after 1240*tbase, '0' after 1250*tbase, '0' after 1260*tbase, '0' after 1270*tbase, '0' after 1280*tbase, '0' after 1290*tbase, '1' after 1300*tbase, '1' after 1310*tbase, --00000010 (send UART) (0x00)
    '0' after 1410*tbase, '1' after 1420*tbase, '0' after 1430*tbase, '0' after 1440*tbase, '0' after 1450*tbase, '1' after 1460*tbase, '0' after 1470*tbase, '1' after 1480*tbase, '0' after 1490*tbase, '1' after 1500*tbase, '1' after 1510*tbase, --0b01010001 (0x51)
    '0' after 1610*tbase, '0' after 1620*tbase, '0' after 1630*tbase, '1' after 1640*tbase, '0' after 1650*tbase, '0' after 1660*tbase, '0' after 1670*tbase, '1' after 1680*tbase, '1' after 1690*tbase, '1' after 1700*tbase, '1' after 1710*tbase, --11000100 (set start value Timer) (0xC2)
    '0' after 1810*tbase, '0' after 1820*tbase, '0' after 1830*tbase, '1' after 1840*tbase, '1' after 1850*tbase, '1' after 1860*tbase, '1' after 1870*tbase, '1' after 1880*tbase, '1' after 1890*tbase, '0' after 1900*tbase, '1' after 1910*tbase, --0b11111100 (0xFC)
    '0' after 2010*tbase, '0' after 2020*tbase, '0' after 2030*tbase, '1' after 2040*tbase, '0' after 2050*tbase, '0' after 2060*tbase, '0' after 2070*tbase, '1' after 2080*tbase, '0' after 2090*tbase, '0' after 2100*tbase, '1' after 2110*tbase, --01000100 (restart Timer) (0x02)
    '0' after 2210*tbase, '1' after 2220*tbase, '1' after 2230*tbase, '1' after 2240*tbase, '1' after 2250*tbase, '1' after 2260*tbase, '1' after 2270*tbase, '1' after 2280*tbase, '1' after 2290*tbase, '0' after 2300*tbase, '1' after 2310*tbase, --0b11111111 (0xFF)
    '0' after 2410*tbase, '0' after 2420*tbase, '0' after 2430*tbase, '1' after 2440*tbase, '0' after 2450*tbase, '0' after 2460*tbase, '0' after 2470*tbase, '0' after 2480*tbase, '0' after 6490*tbase, '1' after 2500*tbase, '1' after 2510*tbase, --00000100 (enable Timer) (0x02)
    '0' after 2610*tbase, '1' after 2620*tbase, '1' after 2630*tbase, '1' after 2640*tbase, '1' after 2650*tbase, '1' after 2660*tbase, '1' after 2670*tbase, '1' after 2680*tbase, '1' after 2690*tbase, '0' after 2700*tbase, '1' after 2710*tbase, --0b11111111 (0xFF)  
    '0' after 3200*tbase, '0' after 3210*tbase, '0' after 3220*tbase, '1' after 3230*tbase, '0' after 3240*tbase, '0' after 3250*tbase, '0' after 3260*tbase, '0' after 3270*tbase, '0' after 3280*tbase, '1' after 3290*tbase, '1' after 3300*tbase, --00000100 (disable Timer) (0x02)
    '0' after 3400*tbase, '0' after 3410*tbase, '0' after 3420*tbase, '0' after 3430*tbase, '0' after 3440*tbase, '0' after 3450*tbase, '0' after 3460*tbase, '0' after 3470*tbase, '0' after 3480*tbase, '0' after 3490*tbase, '1' after 3500*tbase, --0b00000000 (0x00)
    -- Hello World UART stress test
    '0' after 3600*tbase, '0' after 3610*tbase, '1' after 3620*tbase, '0' after 3630*tbase, '0' after 3640*tbase, '0' after 3650*tbase, '0' after 3660*tbase, '0' after 3670*tbase, '0' after 3680*tbase, '1' after 3690*tbase, '1' after 3700*tbase, -- 0x02 (0b00000010)
    '0' after 3710*tbase, '0' after 3720*tbase, '0' after 3730*tbase, '0' after 3740*tbase, '1' after 3750*tbase, '0' after 3760*tbase, '0' after 3770*tbase, '1' after 3780*tbase, '0' after 3790*tbase, '0' after 3800*tbase, '1' after 3810*tbase, -- 'H' (0x48 = 0b01001000)
    -- 180*tbase idle
    '0' after 4000*tbase, '0' after 4010*tbase, '1' after 4020*tbase, '0' after 4030*tbase, '0' after 4040*tbase, '0' after 4050*tbase, '0' after 4060*tbase, '0' after 4070*tbase, '0' after 4080*tbase, '1' after 4090*tbase, '1' after 4100*tbase, -- 0x02 (0b00000010)
    '0' after 4110*tbase, '1' after 4120*tbase, '0' after 4130*tbase, '0' after 4140*tbase, '0' after 4150*tbase, '0' after 4160*tbase, '1' after 4170*tbase, '1' after 4180*tbase, '0' after 4190*tbase, '1' after 4200*tbase, '1' after 4210*tbase, -- 'a' (0x61 = 0b01100001)
    -- 180*tbase idle
    '0' after 4400*tbase, '0' after 4410*tbase, '1' after 4420*tbase, '0' after 4430*tbase, '0' after 4440*tbase, '0' after 4450*tbase, '0' after 4460*tbase, '0' after 4470*tbase, '0' after 4480*tbase, '1' after 4490*tbase, '1' after 4500*tbase, -- 0x02 (0b00000010)
    '0' after 4510*tbase, '0' after 4520*tbase, '0' after 4530*tbase, '1' after 4540*tbase, '1' after 4550*tbase, '0' after 4560*tbase, '1' after 4570*tbase, '1' after 4580*tbase, '0' after 4590*tbase, '0' after 4600*tbase, '1' after 4610*tbase, -- 'l' (0x6C = 0b01101100)
    -- 180*tbase idle
    '0' after 4800*tbase, '0' after 4810*tbase, '1' after 4820*tbase, '0' after 4830*tbase, '0' after 4840*tbase, '0' after 4850*tbase, '0' after 4860*tbase, '0' after 4870*tbase, '0' after 4880*tbase, '1' after 4890*tbase, '1' after 4900*tbase, -- 0x02 (0b00000010)
    '0' after 4910*tbase, '0' after 4920*tbase, '0' after 4930*tbase, '1' after 4940*tbase, '1' after 4950*tbase, '0' after 4960*tbase, '1' after 4970*tbase, '1' after 4980*tbase, '0' after 4990*tbase, '0' after 5000*tbase, '1' after 5010*tbase, -- 'l' (0x6C = 0b01101100)
    -- 180*tbase idle
    '0' after 5200*tbase, '0' after 5210*tbase, '1' after 5220*tbase, '0' after 5230*tbase, '0' after 5240*tbase, '0' after 5250*tbase, '0' after 5260*tbase, '0' after 5270*tbase, '0' after 5280*tbase, '1' after 5290*tbase, '1' after 5300*tbase, -- 0x02 (0b00000010)
    '0' after 5310*tbase, '1' after 5320*tbase, '1' after 5330*tbase, '1' after 5340*tbase, '1' after 5350*tbase, '0' after 5360*tbase, '1' after 5370*tbase, '1' after 5380*tbase, '0' after 5390*tbase, '0' after 5400*tbase, '1' after 5410*tbase, -- 'o' (0x6F = 0b01101111)
    -- 180*tbase idle
    '0' after 5600*tbase, '0' after 5610*tbase, '1' after 5620*tbase, '0' after 5630*tbase, '0' after 5640*tbase, '0' after 5650*tbase, '0' after 5660*tbase, '0' after 5670*tbase, '0' after 5680*tbase, '1' after 5690*tbase, '1' after 5700*tbase, -- 0x02 (0b00000010)
    '0' after 5710*tbase, '0' after 5720*tbase, '0' after 5730*tbase, '0' after 5740*tbase, '0' after 5750*tbase, '0' after 5760*tbase, '1' after 5770*tbase, '0' after 5780*tbase, '0' after 5790*tbase, '1' after 5800*tbase, '1' after 5810*tbase, -- ' ' (0x20 = 0b00100000)
    -- 180*tbase idle
    '0' after 6000*tbase, '0' after 6010*tbase, '1' after 6020*tbase, '0' after 6030*tbase, '0' after 6040*tbase, '0' after 6050*tbase, '0' after 6060*tbase, '0' after 6070*tbase, '0' after 6080*tbase, '1' after 6090*tbase, '1' after 6100*tbase, -- 0x02 (0b00000010)
    '0' after 6110*tbase, '1' after 6120*tbase, '1' after 6130*tbase, '1' after 6140*tbase, '0' after 6150*tbase, '1' after 6160*tbase, '0' after 6170*tbase, '1' after 6180*tbase, '0' after 6190*tbase, '1' after 6200*tbase, '1' after 6210*tbase, -- 'W' (0x57 = 0b01010111)
    -- 180*tbase idle
    '0' after 6400*tbase, '0' after 6410*tbase, '1' after 6420*tbase, '0' after 6430*tbase, '0' after 6440*tbase, '0' after 6450*tbase, '0' after 6460*tbase, '0' after 6470*tbase, '0' after 6480*tbase, '1' after 6490*tbase, '1' after 6500*tbase, -- 0x02 (0b00000010)
    '0' after 6510*tbase, '1' after 6520*tbase, '0' after 6530*tbase, '1' after 6540*tbase, '0' after 6550*tbase, '0' after 6560*tbase, '1' after 6570*tbase, '1' after 6580*tbase, '0' after 6590*tbase, '0' after 6600*tbase, '1' after 6610*tbase, -- 'e' (0x65 = 0b01100101)
    -- 180*tbase idle
    '0' after 6800*tbase, '0' after 6810*tbase, '1' after 6820*tbase, '0' after 6830*tbase, '0' after 6840*tbase, '0' after 6850*tbase, '0' after 6860*tbase, '0' after 6870*tbase, '0' after 6880*tbase, '1' after 6890*tbase, '1' after 6900*tbase, -- 0x02 (0b00000010)
    '0' after 6910*tbase, '0' after 6920*tbase, '0' after 6930*tbase, '1' after 6940*tbase, '1' after 6950*tbase, '0' after 6960*tbase, '1' after 6970*tbase, '1' after 6980*tbase, '0' after 6990*tbase, '0' after 7000*tbase, '1' after 7010*tbase, -- 'l' (0x6C = 0b01101100)
    -- 180*tbase idle
    '0' after 7100*tbase, '0' after 7110*tbase, '1' after 7120*tbase, '0' after 7130*tbase, '0' after 7140*tbase, '0' after 7150*tbase, '0' after 7160*tbase, '0' after 7170*tbase, '0' after 7180*tbase, '1' after 7190*tbase, '1' after 7200*tbase, -- 0x02 (0b00000010)
    '0' after 7210*tbase, '0' after 7220*tbase, '0' after 7230*tbase, '1' after 7240*tbase, '0' after 7250*tbase, '1' after 7260*tbase, '1' after 7270*tbase, '1' after 7280*tbase, '0' after 7290*tbase, '0' after 7300*tbase, '1' after 7310*tbase, -- 't' (0x74 = 0b01110100)
    -- Hello World UART stress test END
    -- RESET Unit test
    '0' after 8000*tbase, '0' after 8010*tbase, '0' after 8020*tbase, '0' after 8030*tbase, '0' after 8040*tbase, '0' after 8050*tbase, '0' after 8060*tbase, '0' after 8070*tbase, '0' after 8080*tbase, '0' after 8090*tbase, '1' after 8100*tbase, -- 0x00 (0b00000000)
    '0' after 8110*tbase, '1' after 8120*tbase, '1' after 8130*tbase, '1' after 8140*tbase, '1' after 8150*tbase, '1' after 8160*tbase, '1' after 8170*tbase, '1' after 8180*tbase, '1' after 8190*tbase, '0' after 8200*tbase, '1' after 8210*tbase, -- 0xFF = 0b11111111
    -- SPI test
    '0' after 8300*tbase, '1' after 8310*tbase, '0' after 8320*tbase, '1' after 8330*tbase, '0' after 8340*tbase, '0' after 8350*tbase, '0' after 8360*tbase, '0' after 8370*tbase, '0' after 8380*tbase, '0' after 8390*tbase, '1' after 8400*tbase, -- 0x00 (0b00000000)
    '0' after 8410*tbase, '1' after 8420*tbase, '0' after 8430*tbase, '1' after 8440*tbase, '0' after 8450*tbase, '0' after 8460*tbase, '1' after 8470*tbase, '0' after 8480*tbase, '1' after 8490*tbase, '0' after 8500*tbase, '1' after 8510*tbase; -- 0xFF = 0b10100101
  
  tb_rx_pin_a <= '1',
    '0' after 100*tbase, '0' after 140*tbase, '0' after 180*tbase, '0' after 220*tbase, '0' after 260*tbase, '1' after 300*tbase, '0' after 340*tbase, '0' after 380*tbase, '0' after 420*tbase, '1' after 460*tbase; --0b00010000

  tb_gpio_pins_in <= "0",
    "1" after 500*tbase,
    "0" after 1100*tbase;

  tb_spi_miso <= '0',
    '0' after 8521*tbase, '0' after 9563*tbase, '1' after 10605*tbase, '1' after 11647*tbase, '0' after 12689*tbase, '0' after 13731*tbase, '0' after 14773*tbase, '0' after 15815*tbase; --0x30;

  tb_exp_tx_pin_host <= '1',
    '0' after 26*tbase, '0' after 36*tbase, '0' after 46*tbase, '0' after 56*tbase, '0' after 66*tbase, '0' after 76*tbase, '0' after 86*tbase, '0' after 96*tbase, '0' after 106*tbase, '0' after 116*tbase, '1' after 126*tbase, --0b00000000 (reset Unit - was reseted - unit)
    '0' after 136*tbase, '1' after 146*tbase, '1' after 156*tbase, '1' after 166*tbase, '1' after 176*tbase, '1' after 186*tbase, '1' after 196*tbase, '1' after 206*tbase, '1' after 216*tbase, '0' after 226*tbase, '1' after 236*tbase, --0b11111111 (reset Unit - was reseted - data)
    '0' after 336*tbase, '1' after 346*tbase, '1' after 356*tbase, '0' after 366*tbase, '0' after 376*tbase, '0' after 386*tbase, '0' after 396*tbase, '0' after 406*tbase, '0' after 416*tbase, '0' after 426*tbase, '1' after 436*tbase, --0b00000011 (get GPIO data - unit) (0x03)
    '0' after 446*tbase, '0' after 456*tbase, '0' after 466*tbase, '0' after 476*tbase, '0' after 486*tbase, '0' after 496*tbase, '0' after 506*tbase, '0' after 516*tbase, '0' after 526*tbase, '0' after 536*tbase, '1' after 546*tbase, --0b00000000 (get GPIO data - data) (0x00)
    '0' after 556*tbase, '0' after 566*tbase, '1' after 576*tbase, '0' after 586*tbase, '0' after 596*tbase, '0' after 606*tbase, '0' after 616*tbase, '0' after 626*tbase, '0' after 636*tbase, '1' after 646*tbase, '1' after 656*tbase, --0b00000010 (UART in - unit) (0x02)
    '0' after 666*tbase, '0' after 676*tbase, '0' after 686*tbase, '0' after 696*tbase, '0' after 706*tbase, '1' after 716*tbase, '0' after 726*tbase, '0' after 736*tbase, '0' after 746*tbase, '1' after 756*tbase, '1' after 766*tbase, --0b00010000 (UART in - data) (0x10)
    '0' after 776*tbase, '1' after 786*tbase, '1' after 796*tbase, '0' after 806*tbase, '0' after 816*tbase, '0' after 826*tbase, '0' after 836*tbase, '0' after 846*tbase, '0' after 856*tbase, '0' after 866*tbase, '1' after 876*tbase, --0b00000011 (GPIO interrupt - unit) (0x03)
    '0' after 886*tbase, '1' after 896*tbase, '0' after 906*tbase, '0' after 916*tbase, '0' after 926*tbase, '0' after 936*tbase, '0' after 946*tbase, '0' after 956*tbase, '0' after 966*tbase, '1' after 976*tbase, '1' after 986*tbase, --0b00000000 (GPIO interrupt - data) (0x01)
    '0' after 1116*tbase, '1' after 1126*tbase, '1' after 1136*tbase, '0' after 1146*tbase, '0' after 1156*tbase, '0' after 1166*tbase, '0' after 1176*tbase, '0' after 1186*tbase, '0' after 1196*tbase, '0' after 1206*tbase, '1' after 1216*tbase, --0b00000011 (GPIO interrupt - unit) (0x03)
    '0' after 1226*tbase, '0' after 1236*tbase, '0' after 1246*tbase, '0' after 1256*tbase, '0' after 1266*tbase, '0' after 1276*tbase, '0' after 1286*tbase, '0' after 1296*tbase, '0' after 1306*tbase, '0' after 1316*tbase, '1' after 1326*tbase, --0b00000000 (GPIO interrupt - data) (0x00)
    '0' after 3126*tbase, '0' after 3136*tbase, '0' after 3146*tbase, '1' after 3156*tbase, '0' after 3166*tbase, '0' after 3176*tbase, '0' after 3186*tbase, '0' after 3186*tbase, '0' after 3206*tbase, '1' after 3216*tbase, '1' after 3226*tbase, --0b00000100 (Timer interrupt - unit) (0x04)
    '0' after 3236*tbase, '1' after 3246*tbase, '1' after 3256*tbase, '1' after 3266*tbase, '1' after 3276*tbase, '1' after 3286*tbase, '1' after 3296*tbase, '1' after 3306*tbase, '1' after 3316*tbase, '0' after 3326*tbase, '1' after 3336*tbase, --0b11111111 (Timer interrupt - data) (0xFF)
    '0' after 8245*tbase, '0' after 8255*tbase, '0' after 8265*tbase, '0' after 8275*tbase, '0' after 8285*tbase, '0' after 8295*tbase, '0' after 8305*tbase, '0' after 8315*tbase, '0' after 8325*tbase, '0' after 8335*tbase, '1' after 8345*tbase, --0b00000000 (Reset unit - unit) (0x00)
    '0' after 8355*tbase, '1' after 8365*tbase, '1' after 8375*tbase, '1' after 8385*tbase, '1' after 8395*tbase, '1' after 8405*tbase, '1' after 8415*tbase, '1' after 8425*tbase, '1' after 8435*tbase, '0' after 8445*tbase, '1' after 8455*tbase, --0b11111111 (Reset unit - data) (0xFF)
    '0' after 16355*tbase, '1' after 16365*tbase, '0' after 16375*tbase, '1' after 16385*tbase, '0' after 16395*tbase, '0' after 16405*tbase, '0' after 16415*tbase, '0' after 16425*tbase, '0' after 16435*tbase, '0' after 16445*tbase, '1' after 16455*tbase, --0b00000101 (SPI unit - unit) (0x05)
    '0' after 16465*tbase, '0' after 16475*tbase, '0' after 16485*tbase, '0' after 16495*tbase, '0' after 16505*tbase, '1' after 16515*tbase, '1' after 16525*tbase, '0' after 16535*tbase, '0' after 16545*tbase, '0' after 16555*tbase, '1' after 16565*tbase; --0b00110000 (SPI unit - data) (0x30)

  tb_exp_tx_pin_a <= '1',
    '0' after 1181*tbase, '1' after 1221*tbase, '0' after 1261*tbase, '1' after 1301*tbase, '1' after 1341*tbase, '1' after 1381*tbase, '1' after 1421*tbase, '1' after 1461*tbase, '0' after 1501*tbase, '1' after 1541*tbase, --0b01111101 (0x7D)
    '0' after 1581*tbase, '1' after 1621*tbase, '0' after 1661*tbase, '0' after 1701*tbase, '0' after 1741*tbase, '1' after 1781*tbase, '0' after 1821*tbase, '1' after 1861*tbase, '0' after 1901*tbase, '1' after 1941*tbase, --0b01010001 (0x51)
    -- Hello World UART stress test
    '0' after 3861*tbase, '0' after 3901*tbase, '0' after 3941*tbase, '0' after 3981*tbase, '1' after 4021*tbase, '0' after 4061*tbase, '0' after 4101*tbase, '1' after 4141*tbase, '0' after 4181*tbase, '1' after 4221*tbase, -- 'H' (0x48 = 0b01001000)
    '0' after 4261*tbase, '1' after 4301*tbase, '0' after 4341*tbase, '0' after 4381*tbase, '0' after 4421*tbase, '0' after 4461*tbase, '1' after 4501*tbase, '1' after 4541*tbase, '0' after 4581*tbase, '1' after 4621*tbase, -- 'a' (0x61 = 0b01100001)  
    '0' after 4661*tbase, '0' after 4701*tbase, '0' after 4741*tbase, '1' after 4781*tbase, '1' after 4821*tbase, '0' after 4861*tbase, '1' after 4901*tbase, '1' after 4941*tbase, '0' after 4981*tbase, '1' after 5021*tbase, -- 'l' (0x6C = 0b01101100)
    '0' after 5061*tbase, '0' after 5101*tbase, '0' after 5141*tbase, '1' after 5181*tbase, '1' after 5221*tbase, '0' after 5261*tbase, '1' after 5301*tbase, '1' after 5341*tbase, '0' after 5381*tbase, '1' after 5421*tbase, -- 'l' (0x6C = 0b01101100) 
    '0' after 5461*tbase, '1' after 5501*tbase, '1' after 5541*tbase, '1' after 5581*tbase, '1' after 5621*tbase, '0' after 5661*tbase, '1' after 5701*tbase, '1' after 5741*tbase, '0' after 5781*tbase, '1' after 5821*tbase, -- 'o' (0x6F = 0b01101111) 
    '0' after 5861*tbase, '0' after 5901*tbase, '0' after 5941*tbase, '0' after 5981*tbase, '0' after 6021*tbase, '0' after 6061*tbase, '1' after 6101*tbase, '0' after 6141*tbase, '0' after 6181*tbase, '1' after 6221*tbase, -- ' ' (0x20 = 0b00100000)  
    '0' after 6261*tbase, '1' after 6301*tbase, '1' after 6341*tbase, '1' after 6381*tbase, '0' after 6421*tbase, '1' after 6461*tbase, '0' after 6501*tbase, '1' after 6541*tbase, '0' after 6581*tbase, '1' after 6621*tbase, -- 'W' (0x57 = 0b01010111)
    '0' after 6661*tbase, '1' after 6701*tbase, '0' after 6741*tbase, '1' after 6781*tbase, '0' after 6821*tbase, '0' after 6861*tbase, '1' after 6901*tbase, '1' after 6941*tbase, '0' after 6981*tbase, '1' after 7021*tbase, -- 'e' (0x65 = 0b01100101)
    '0' after 7061*tbase, '0' after 7101*tbase, '0' after 7141*tbase, '1' after 7181*tbase, '1' after 7221*tbase, '0' after 7261*tbase, '1' after 7301*tbase, '1' after 7341*tbase, '0' after 7381*tbase, '1' after 7421*tbase, -- 'l' (0x6C = 0b01101100)  
    '0' after 7461*tbase, '0' after 7501*tbase, '0' after 7541*tbase, '1' after 7581*tbase, '0' after 7621*tbase, '1' after 7661*tbase, '1' after 7701*tbase, '1' after 7741*tbase, '0' after 7781*tbase, '1' after 7821*tbase; -- 't' (0x74 = 0b01110100) 

  tb_exp_gpio_pins_out <= "UU", "00" after 1*tbase,
    "10" after 720*tbase,
    "00" after 8220*tbase;

  tb_exp_spi_sck <= '0',
    '1' after 9042*tbase, '0' after 9563*tbase, 
    '1' after 10084*tbase, '0' after 10605*tbase, 
    '1' after 11126*tbase, '0' after 11647*tbase, 
    '1' after 12168*tbase, '0' after 12689*tbase, 
    '1' after 13210*tbase, '0' after 13731*tbase, 
    '1' after 14252*tbase, '0' after 14773*tbase, 
    '1' after 15294*tbase, '0' after 15815*tbase, 
    '1' after 16336*tbase, '0' after 16857*tbase;

  tb_exp_spi_cs <= "1",
    "0" after 8521*tbase, "1" after 16860*tbase;

  tb_exp_spi_mosi <= '0',
    '1' after 8521*tbase, '0' after 9563*tbase, '1' after 10605*tbase, '0' after 11647*tbase, '0' after 12689*tbase, '1' after 13731*tbase, '0' after 14773*tbase, '1' after 15815*tbase, '0' after 16857*tbase;

  tb_error <= '0' when 
    (tb_exp_tx_pin_host = tb_tx_pin_host)
    and (tb_exp_tx_pin_a = tb_tx_pin_a)
    and (tb_exp_gpio_pins_out = tb_gpio_pins_out) 
    and (tb_exp_spi_sck = tb_spi_sck)
    and (tb_exp_spi_cs = tb_spi_cs)
    and (tb_exp_spi_mosi = tb_spi_mosi) else '1';

end TESTBENCH;