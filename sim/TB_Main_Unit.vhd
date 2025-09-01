--! @file
--! @brief Testbench for the Main_Unit
--! @details
--! This file contains the testbench for the Main_Unit entity.  
--! It tests:
--! - Reset Unit: reset/get reset
--! - Error Unit: -
--! - ACK Unit: ACK enable, disable, get ACK
--! - UART Unit: send, receive + stress testing sending more load
--! - GPIO Unit: set, get, interrupt
--! - Timer Unit: set start value, restart, enable, disable
--! - SPI Unit: receive, send
--! - I2C Unit: send, receive, set adr.
--! - SRAM Unit: save, read, set adr.
--!
--! The tested configuration of Main_Unit is:
--! - ExtPack Management --> generic map(10000000, 1000000, 8, 1, 1, 0)
--! - Special units:
--!   - U0: Reset --> generic map(8)
--!   - U1: Error --> generic map(8)
--!   - U2: ACK --> generic map(8, 2)
--! - Normal units:
--!   - U3: UART --> generic map(8, 12000000, 250000, 8, 1, 0, 0)
--!   - U4: GPIO --> generic map(8, 1, 2)
--!   - U5: Timer --> generic map(8, 12000000, 1000000)
--!   - U6: SPI --> generic map(8, 12000000, 9600, 1, 0, 0, 8)
--!   - U7: I2C --> generic map(8, 12000000, 100000)
--!   - U8: SRAM --> generic map(8, 12000000, 8)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Main_Unit is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_Main_Unit;

architecture TESTBENCH of TB_Main_Unit is
  component Main_Unit
    Generic(
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000;
      HOST_DATA_BITS : integer := 8;
      HOST_STOP_BITS : integer := 1;
      HOST_PARITY_ACTIVE : integer := 0;
      HOST_PARITY_MODE : integer := 0
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
      spi_miso : in std_logic;
      i2c_scl : inout std_logic;
      i2c_sda : inout std_logic;
      sram_adr : out std_logic_vector(18 downto 0);
      sram_data : inout std_logic_vector(7 downto 0);
      sram_oen : out std_logic := '1';
      sram_cen : out std_logic := '1';
      sram_wen : out std_logic := '1'
      
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
  signal tb_i2c_scl, tb_exp_i2c_scl, tb_i2c_scl_no_pullup : std_logic;
  signal tb_i2c_sda, tb_exp_i2c_sda, tb_i2c_sda_no_pullup : std_logic;
  signal tb_sram_adr, tb_exp_sram_adr : std_logic_vector(18 downto 0);
  signal tb_sram_data, tb_exp_sram_data, tb_sram_data_no_pullup : std_logic_vector(7 downto 0);
  signal tb_sram_oen, tb_exp_sram_oen : std_logic := '1';
  signal tb_sram_cen, tb_exp_sram_cen : std_logic := '1';
  signal tb_sram_wen, tb_exp_sram_wen : std_logic := '1';

  constant tbase : time := 100 ns;
  constant tbase_i2c_scl : time := 10000 ns;

  signal exp_SCL_temp : std_logic;
  signal exp_SCL_en : std_logic;
begin
  MU: Main_Unit generic map(10000000, 1000000, 8, 1, 1, 0) port map(tb_clk, tb_rst, tb_tx_pin_host, tb_rx_pin_host, tb_tx_pin_a, tb_rx_pin_a, tb_gpio_pins_in, tb_gpio_pins_out, tb_spi_sck, tb_spi_cs, tb_spi_mosi, tb_spi_miso, tb_i2c_scl_no_pullup, tb_i2c_sda_no_pullup, tb_sram_adr, tb_sram_data_no_pullup, tb_sram_oen, tb_sram_cen, tb_sram_wen);
  
  tb_i2c_sda <= tb_i2c_sda_no_pullup when tb_i2c_sda_no_pullup /= 'Z' else 'H';
  tb_i2c_scl <= tb_i2c_scl_no_pullup when tb_i2c_scl_no_pullup /= 'Z' else 'H';
  tb_sram_data <= tb_sram_data_no_pullup when tb_sram_data_no_pullup /= "ZZZZZZZZ" else (others => 'H');

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

  -- 100 KHz
  CLOCK_CLA: process
  begin
    exp_SCL_temp <= '0';
    wait for 3*tbase; -- Init Prescaler because of reset
    for i in 81 downto 0 loop
      exp_SCL_temp <= '0';
      wait for tbase_i2c_scl/2;
      exp_SCL_temp <= '1';
      wait for tbase_i2c_scl/2;
    end loop;
    exp_SCL_temp <= '0';
    wait for 19*tbase; -- Reset unit test
    for i in 117 downto 0 loop
      exp_SCL_temp <= '0';
      wait for tbase_i2c_scl/2;
      exp_SCL_temp <= '1';
      wait for tbase_i2c_scl/2;
    end loop;
    exp_SCL_temp <= '0';
    wait;
  end process;

  exp_SCL_en <= '1', '0' after 1*tbase,
    '1' after 9922*tbase, '0' after 13672*tbase;

  tb_exp_i2c_scl <= '0' when exp_SCL_en = '1' and exp_SCL_temp = '0' else 'H';

  tb_rst <= '1', '0' after 2*tbase;

  tb_rx_pin_host <= '1',
    '0' after 10*tbase, '0' after 20*tbase, '0' after 30*tbase, '1' after 40*tbase, '0' after 50*tbase, '0' after 60*tbase, '0' after 70*tbase, '1' after 80*tbase, '0' after 90*tbase, '0' after 100*tbase, '1' after 110*tbase, --0b01000100 (get GPIO data) (0x44)
    '0' after 210*tbase, '1' after 220*tbase, '1' after 230*tbase, '1' after 240*tbase, '1' after 250*tbase, '1' after 260*tbase, '1' after 270*tbase, '1' after 280*tbase, '1' after 290*tbase, '0' after 300*tbase, '1' after 310*tbase, --0b11111111 (0xFF)
    '0' after 410*tbase, '0' after 420*tbase, '0' after 430*tbase, '1' after 440*tbase, '0' after 450*tbase, '0' after 460*tbase, '0' after 470*tbase, '0' after 480*tbase, '0' after 490*tbase, '1' after 500*tbase, '1' after 510*tbase, --00000100 (set GPIO data) (0x04)
    '0' after 610*tbase, '0' after 620*tbase, '1' after 630*tbase, '1' after 640*tbase, '1' after 650*tbase, '1' after 660*tbase, '1' after 670*tbase, '1' after 680*tbase, '1' after 690*tbase, '1' after 700*tbase, '1' after 710*tbase, --0b11111110 (0xFE)
    '0' after 810*tbase, '1' after 820*tbase, '1' after 830*tbase, '0' after 840*tbase, '0' after 850*tbase, '0' after 860*tbase, '0' after 870*tbase, '0' after 880*tbase, '0' after 890*tbase, '0' after 900*tbase, '1' after 910*tbase, --00000011 (send UART) (0x03)
    '0' after 1010*tbase, '1' after 1020*tbase, '0' after 1030*tbase, '1' after 1040*tbase, '1' after 1050*tbase, '1' after 1060*tbase, '1' after 1070*tbase, '1' after 1080*tbase, '0' after 1090*tbase, '0' after 1100*tbase, '1' after 1110*tbase, --0b01111101 (0x7D)
    '0' after 1210*tbase, '1' after 1220*tbase, '1' after 1230*tbase, '0' after 1240*tbase, '0' after 1250*tbase, '0' after 1260*tbase, '0' after 1270*tbase, '0' after 1280*tbase, '0' after 1290*tbase, '0' after 1300*tbase, '1' after 1310*tbase, --00000011 (send UART) (0x03)
    '0' after 1410*tbase, '1' after 1420*tbase, '0' after 1430*tbase, '0' after 1440*tbase, '0' after 1450*tbase, '1' after 1460*tbase, '0' after 1470*tbase, '1' after 1480*tbase, '0' after 1490*tbase, '1' after 1500*tbase, '1' after 1510*tbase, --0b01010001 (0x51)
    '0' after 1610*tbase, '1' after 1620*tbase, '0' after 1630*tbase, '1' after 1640*tbase, '0' after 1650*tbase, '0' after 1660*tbase, '0' after 1670*tbase, '1' after 1680*tbase, '1' after 1690*tbase, '0' after 1700*tbase, '1' after 1710*tbase, --11000101 (set start value Timer) (0xC3)
    '0' after 1810*tbase, '0' after 1820*tbase, '0' after 1830*tbase, '1' after 1840*tbase, '1' after 1850*tbase, '1' after 1860*tbase, '1' after 1870*tbase, '1' after 1880*tbase, '1' after 1890*tbase, '0' after 1900*tbase, '1' after 1910*tbase, --0b11111100 (0xFC)
    '0' after 2010*tbase, '1' after 2020*tbase, '0' after 2030*tbase, '1' after 2040*tbase, '0' after 2050*tbase, '0' after 2060*tbase, '0' after 2070*tbase, '1' after 2080*tbase, '0' after 2090*tbase, '1' after 2100*tbase, '1' after 2110*tbase, --01000101 (restart Timer) (0x03)
    '0' after 2210*tbase, '1' after 2220*tbase, '1' after 2230*tbase, '1' after 2240*tbase, '1' after 2250*tbase, '1' after 2260*tbase, '1' after 2270*tbase, '1' after 2280*tbase, '1' after 2290*tbase, '0' after 2300*tbase, '1' after 2310*tbase, --0b11111111 (0xFF)
    '0' after 2410*tbase, '1' after 2420*tbase, '0' after 2430*tbase, '1' after 2440*tbase, '0' after 2450*tbase, '0' after 2460*tbase, '0' after 2470*tbase, '0' after 2480*tbase, '0' after 6490*tbase, '0' after 2500*tbase, '1' after 2510*tbase, --00000101 (enable Timer) (0x03)
    '0' after 2610*tbase, '1' after 2620*tbase, '1' after 2630*tbase, '1' after 2640*tbase, '1' after 2650*tbase, '1' after 2660*tbase, '1' after 2670*tbase, '1' after 2680*tbase, '1' after 2690*tbase, '0' after 2700*tbase, '1' after 2710*tbase, --0b11111111 (0xFF)  
    '0' after 3200*tbase, '1' after 3210*tbase, '0' after 3220*tbase, '1' after 3230*tbase, '0' after 3240*tbase, '0' after 3250*tbase, '0' after 3260*tbase, '0' after 3270*tbase, '0' after 3280*tbase, '0' after 3290*tbase, '1' after 3300*tbase, --00000101 (disable Timer) (0x03)
    '0' after 3400*tbase, '0' after 3410*tbase, '0' after 3420*tbase, '0' after 3430*tbase, '0' after 3440*tbase, '0' after 3450*tbase, '0' after 3460*tbase, '0' after 3470*tbase, '0' after 3480*tbase, '0' after 3490*tbase, '1' after 3500*tbase, --0b00000000 (0x00)
    -- Hello World UART stress test
    '0' after 3600*tbase, '1' after 3610*tbase, '1' after 3620*tbase, '0' after 3630*tbase, '0' after 3640*tbase, '0' after 3650*tbase, '0' after 3660*tbase, '0' after 3670*tbase, '0' after 3680*tbase, '0' after 3690*tbase, '1' after 3700*tbase, -- 0x03 (0b00000011)
    '0' after 3710*tbase, '0' after 3720*tbase, '0' after 3730*tbase, '0' after 3740*tbase, '1' after 3750*tbase, '0' after 3760*tbase, '0' after 3770*tbase, '1' after 3780*tbase, '0' after 3790*tbase, '0' after 3800*tbase, '1' after 3810*tbase, -- 'H' (0x48 = 0b01001000)
    -- 180*tbase idle
    '0' after 4000*tbase, '1' after 4010*tbase, '1' after 4020*tbase, '0' after 4030*tbase, '0' after 4040*tbase, '0' after 4050*tbase, '0' after 4060*tbase, '0' after 4070*tbase, '0' after 4080*tbase, '0' after 4090*tbase, '1' after 4100*tbase, -- 0x03 (0b00000011)
    '0' after 4110*tbase, '1' after 4120*tbase, '0' after 4130*tbase, '0' after 4140*tbase, '0' after 4150*tbase, '0' after 4160*tbase, '1' after 4170*tbase, '1' after 4180*tbase, '0' after 4190*tbase, '1' after 4200*tbase, '1' after 4210*tbase, -- 'a' (0x61 = 0b01100001)
    -- 180*tbase idle
    '0' after 4400*tbase, '1' after 4410*tbase, '1' after 4420*tbase, '0' after 4430*tbase, '0' after 4440*tbase, '0' after 4450*tbase, '0' after 4460*tbase, '0' after 4470*tbase, '0' after 4480*tbase, '0' after 4490*tbase, '1' after 4500*tbase, -- 0x03 (0b00000011)
    '0' after 4510*tbase, '0' after 4520*tbase, '0' after 4530*tbase, '1' after 4540*tbase, '1' after 4550*tbase, '0' after 4560*tbase, '1' after 4570*tbase, '1' after 4580*tbase, '0' after 4590*tbase, '0' after 4600*tbase, '1' after 4610*tbase, -- 'l' (0x6C = 0b01101100)
    -- 180*tbase idle
    '0' after 4800*tbase, '1' after 4810*tbase, '1' after 4820*tbase, '0' after 4830*tbase, '0' after 4840*tbase, '0' after 4850*tbase, '0' after 4860*tbase, '0' after 4870*tbase, '0' after 4880*tbase, '0' after 4890*tbase, '1' after 4900*tbase, -- 0x03 (0b00000011)
    '0' after 4910*tbase, '0' after 4920*tbase, '0' after 4930*tbase, '1' after 4940*tbase, '1' after 4950*tbase, '0' after 4960*tbase, '1' after 4970*tbase, '1' after 4980*tbase, '0' after 4990*tbase, '0' after 5000*tbase, '1' after 5010*tbase, -- 'l' (0x6C = 0b01101100)
    -- 180*tbase idle
    '0' after 5200*tbase, '1' after 5210*tbase, '1' after 5220*tbase, '0' after 5230*tbase, '0' after 5240*tbase, '0' after 5250*tbase, '0' after 5260*tbase, '0' after 5270*tbase, '0' after 5280*tbase, '0' after 5290*tbase, '1' after 5300*tbase, -- 0x03 (0b00000011)
    '0' after 5310*tbase, '1' after 5320*tbase, '1' after 5330*tbase, '1' after 5340*tbase, '1' after 5350*tbase, '0' after 5360*tbase, '1' after 5370*tbase, '1' after 5380*tbase, '0' after 5390*tbase, '0' after 5400*tbase, '1' after 5410*tbase, -- 'o' (0x6F = 0b01101111)
    -- 180*tbase idle
    '0' after 5600*tbase, '1' after 5610*tbase, '1' after 5620*tbase, '0' after 5630*tbase, '0' after 5640*tbase, '0' after 5650*tbase, '0' after 5660*tbase, '0' after 5670*tbase, '0' after 5680*tbase, '0' after 5690*tbase, '1' after 5700*tbase, -- 0x03 (0b00000011)
    '0' after 5710*tbase, '0' after 5720*tbase, '0' after 5730*tbase, '0' after 5740*tbase, '0' after 5750*tbase, '0' after 5760*tbase, '1' after 5770*tbase, '0' after 5780*tbase, '0' after 5790*tbase, '1' after 5800*tbase, '1' after 5810*tbase, -- ' ' (0x20 = 0b00100000)
    -- 180*tbase idle
    '0' after 6000*tbase, '1' after 6010*tbase, '1' after 6020*tbase, '0' after 6030*tbase, '0' after 6040*tbase, '0' after 6050*tbase, '0' after 6060*tbase, '0' after 6070*tbase, '0' after 6080*tbase, '0' after 6090*tbase, '1' after 6100*tbase, -- 0x03 (0b00000011)
    '0' after 6110*tbase, '1' after 6120*tbase, '1' after 6130*tbase, '1' after 6140*tbase, '0' after 6150*tbase, '1' after 6160*tbase, '0' after 6170*tbase, '1' after 6180*tbase, '0' after 6190*tbase, '1' after 6200*tbase, '1' after 6210*tbase, -- 'W' (0x57 = 0b01010111)
    -- 180*tbase idle
    '0' after 6400*tbase, '1' after 6410*tbase, '1' after 6420*tbase, '0' after 6430*tbase, '0' after 6440*tbase, '0' after 6450*tbase, '0' after 6460*tbase, '0' after 6470*tbase, '0' after 6480*tbase, '0' after 6490*tbase, '1' after 6500*tbase, -- 0x03 (0b00000011)
    '0' after 6510*tbase, '1' after 6520*tbase, '0' after 6530*tbase, '1' after 6540*tbase, '0' after 6550*tbase, '0' after 6560*tbase, '1' after 6570*tbase, '1' after 6580*tbase, '0' after 6590*tbase, '0' after 6600*tbase, '1' after 6610*tbase, -- 'e' (0x65 = 0b01100101)
    -- 180*tbase idle
    '0' after 6800*tbase, '1' after 6810*tbase, '1' after 6820*tbase, '0' after 6830*tbase, '0' after 6840*tbase, '0' after 6850*tbase, '0' after 6860*tbase, '0' after 6870*tbase, '0' after 6880*tbase, '0' after 6890*tbase, '1' after 6900*tbase, -- 0x03 (0b00000011)
    '0' after 6910*tbase, '0' after 6920*tbase, '0' after 6930*tbase, '1' after 6940*tbase, '1' after 6950*tbase, '0' after 6960*tbase, '1' after 6970*tbase, '1' after 6980*tbase, '0' after 6990*tbase, '0' after 7000*tbase, '1' after 7010*tbase, -- 'l' (0x6C = 0b01101100)
    -- 180*tbase idle
    '0' after 7100*tbase, '1' after 7110*tbase, '1' after 7120*tbase, '0' after 7130*tbase, '0' after 7140*tbase, '0' after 7150*tbase, '0' after 7160*tbase, '0' after 7170*tbase, '0' after 7180*tbase, '0' after 7190*tbase, '1' after 7200*tbase, -- 0x03 (0b00000011)
    '0' after 7210*tbase, '0' after 7220*tbase, '0' after 7230*tbase, '1' after 7240*tbase, '0' after 7250*tbase, '1' after 7260*tbase, '1' after 7270*tbase, '1' after 7280*tbase, '0' after 7290*tbase, '0' after 7300*tbase, '1' after 7310*tbase, -- 't' (0x74 = 0b01110100)
    -- Hello World UART stress test END
    -- RESET Unit test
    '0' after 8000*tbase, '0' after 8010*tbase, '0' after 8020*tbase, '0' after 8030*tbase, '0' after 8040*tbase, '0' after 8050*tbase, '0' after 8060*tbase, '0' after 8070*tbase, '0' after 8080*tbase, '0' after 8090*tbase, '1' after 8100*tbase, -- 0x00 (0b00000000)
    '0' after 8110*tbase, '1' after 8120*tbase, '1' after 8130*tbase, '1' after 8140*tbase, '1' after 8150*tbase, '1' after 8160*tbase, '1' after 8170*tbase, '1' after 8180*tbase, '1' after 8190*tbase, '0' after 8200*tbase, '1' after 8210*tbase, -- 0xFF = 0b11111111
    -- ACK test
    '0' after 8300*tbase, '0' after 8310*tbase, '1' after 8320*tbase, '0' after 8330*tbase, '0' after 8340*tbase, '0' after 8350*tbase, '0' after 8360*tbase, '0' after 8370*tbase, '0' after 8380*tbase, '1' after 8390*tbase, '1' after 8400*tbase, -- 0x02 (0b00000010)
    '0' after 8410*tbase, '1' after 8420*tbase, '1' after 8430*tbase, '1' after 8440*tbase, '1' after 8450*tbase, '1' after 8460*tbase, '1' after 8470*tbase, '1' after 8480*tbase, '1' after 8490*tbase, '0' after 8500*tbase, '1' after 8510*tbase, -- 0xFF = 0b11111111
    -- SPI test
    '0' after 8600*tbase, '0' after 8610*tbase, '1' after 8620*tbase, '1' after 8630*tbase, '0' after 8640*tbase, '0' after 8650*tbase, '0' after 8660*tbase, '0' after 8670*tbase, '0' after 8680*tbase, '0' after 8690*tbase, '1' after 8700*tbase, -- 0x06 (0b00000110)
    '0' after 8710*tbase, '1' after 8720*tbase, '0' after 8730*tbase, '1' after 8740*tbase, '0' after 8750*tbase, '0' after 8760*tbase, '1' after 8770*tbase, '0' after 8780*tbase, '1' after 8790*tbase, '0' after 8800*tbase, '1' after 8810*tbase, -- 0xA5 = 0b10100101
    -- ACK test end
    '0' after 8900*tbase, '0' after 8910*tbase, '1' after 8920*tbase, '0' after 8930*tbase, '0' after 8940*tbase, '0' after 8950*tbase, '0' after 8960*tbase, '0' after 8970*tbase, '0' after 8980*tbase, '1' after 8990*tbase, '1' after 9000*tbase, -- 0x02 (0b00000010)
    '0' after 9010*tbase, '0' after 9020*tbase, '0' after 9030*tbase, '0' after 9040*tbase, '0' after 9050*tbase, '0' after 9060*tbase, '0' after 9070*tbase, '0' after 9080*tbase, '0' after 9090*tbase, '0' after 9100*tbase, '1' after 9110*tbase, -- 0x00 = 0b00000000
    -- I2C test
    '0' after 9300*tbase, '1' after 9310*tbase, '1' after 9320*tbase, '1' after 9330*tbase, '0' after 9340*tbase, '0' after 9350*tbase, '0' after 9360*tbase, '1' after 9370*tbase, '0' after 9380*tbase, '0' after 9390*tbase, '1' after 9400*tbase, -- 0x47 (0b01000111) (set partner adr)
    '0' after 9410*tbase, '1' after 9420*tbase, '0' after 9430*tbase, '0' after 9440*tbase, '0' after 9450*tbase, '0' after 9460*tbase, '0' after 9470*tbase, '0' after 9480*tbase, '0' after 9490*tbase, '1' after 9500*tbase, '1' after 9510*tbase, -- 0x01 = 0b00000001
    '0' after 9600*tbase, '1' after 9610*tbase, '1' after 9620*tbase, '1' after 9630*tbase, '0' after 9640*tbase, '0' after 9650*tbase, '0' after 9660*tbase, '0' after 9670*tbase, '0' after 9680*tbase, '1' after 9690*tbase, '1' after 9700*tbase, -- 0x07 (0b00000111) (send)
    '0' after 9710*tbase, '0' after 9720*tbase, '0' after 9730*tbase, '0' after 9740*tbase, '0' after 9750*tbase, '1' after 9760*tbase, '1' after 9770*tbase, '1' after 9780*tbase, '1' after 9790*tbase, '0' after 9800*tbase, '1' after 9810*tbase, -- 0xF0 = 11110000
    '0' after 9900*tbase, '1' after 9910*tbase, '1' after 9920*tbase, '1' after 9930*tbase, '0' after 9940*tbase, '0' after 9950*tbase, '0' after 9960*tbase, '0' after 9970*tbase, '1' after 9980*tbase, '0' after 9990*tbase, '1' after 10000*tbase, -- 0x87 (0b10000111) (recv)
    '0' after 10010*tbase, '0' after 10020*tbase, '0' after 10030*tbase, '0' after 10040*tbase, '0' after 10050*tbase, '1' after 10060*tbase, '1' after 10070*tbase, '1' after 10080*tbase, '1' after 10090*tbase, '0' after 10100*tbase, '1' after 10110*tbase, -- 0xF0 = 11110000 -- Ignored
    -- SRAM test
    '0' after 10500*tbase, '0' after 10510*tbase, '0' after 10520*tbase, '0' after 10530*tbase, '1' after 10540*tbase, '0' after 10550*tbase, '0' after 10560*tbase, '1' after 10570*tbase, '0' after 10580*tbase, '0' after 10590*tbase, '1' after 10600*tbase, -- 0x48 (01001000) (set SRAM adr)
    '0' after 10700*tbase, '0' after 10710*tbase, '0' after 10720*tbase, '0' after 10730*tbase, '0' after 10740*tbase, '1' after 10750*tbase, '1' after 10760*tbase, '1' after 10770*tbase, '1' after 10780*tbase, '0' after 10790*tbase, '1' after 10800*tbase, -- 0xF0 (11110000)
    '0' after 10810*tbase, '0' after 10820*tbase, '0' after 10830*tbase, '0' after 10840*tbase, '1' after 10850*tbase, '0' after 10860*tbase, '0' after 10870*tbase, '1' after 10880*tbase, '0' after 10890*tbase, '0' after 10900*tbase, '1' after 10910*tbase, -- 0x48 (01001000) (set SRAM adr)
    '0' after 11010*tbase, '1' after 11020*tbase, '1' after 11030*tbase, '1' after 11040*tbase, '1' after 11050*tbase, '0' after 11060*tbase, '0' after 11070*tbase, '0' after 11080*tbase, '0' after 11090*tbase, '0' after 11100*tbase, '1' after 11110*tbase, -- 0x0F (00001111)
    '0' after 11120*tbase, '0' after 11130*tbase, '0' after 11140*tbase, '0' after 11150*tbase, '1' after 11160*tbase, '0' after 11170*tbase, '0' after 11180*tbase, '1' after 11190*tbase, '0' after 11200*tbase, '0' after 11210*tbase, '1' after 11220*tbase, -- 0x48 (01001000) (set SRAM adr)
    '0' after 11320*tbase, '1' after 11330*tbase, '0' after 11340*tbase, '0' after 11350*tbase, '0' after 11360*tbase, '0' after 11370*tbase, '0' after 11380*tbase, '0' after 11390*tbase, '0' after 11400*tbase, '1' after 11410*tbase, '1' after 11420*tbase, -- 0x01 (00000001)
    '0' after 11430*tbase, '0' after 11440*tbase, '0' after 11450*tbase, '0' after 11460*tbase, '1' after 11470*tbase, '0' after 11480*tbase, '0' after 11490*tbase, '1' after 11500*tbase, '1' after 11510*tbase, '1' after 11520*tbase, '1' after 11530*tbase, -- 0xC8 (11001000) (Write SRAM)
    '0' after 11630*tbase, '1' after 11640*tbase, '1' after 11650*tbase, '1' after 11660*tbase, '1' after 11670*tbase, '1' after 11680*tbase, '1' after 11690*tbase, '0' after 11700*tbase, '0' after 11710*tbase, '0' after 11720*tbase, '1' after 11730*tbase, -- 0x3F (00111111)
    '0' after 11740*tbase, '0' after 11750*tbase, '0' after 11760*tbase, '0' after 11770*tbase, '1' after 11780*tbase, '0' after 11790*tbase, '0' after 11800*tbase, '0' after 11810*tbase, '1' after 11820*tbase, '0' after 11830*tbase, '1' after 11840*tbase, -- 0x88 (1001000) (Read SRAM)
    '0' after 11940*tbase, '0' after 11950*tbase, '0' after 11960*tbase, '0' after 11970*tbase, '0' after 11980*tbase, '0' after 11990*tbase, '0' after 12000*tbase, '0' after 12010*tbase, '0' after 12020*tbase, '0' after 12030*tbase, '1' after 12040*tbase; -- 0x00 (00000000)

  tb_rx_pin_a <= '1',
    '0' after 100*tbase, '0' after 140*tbase, '0' after 180*tbase, '0' after 220*tbase, '0' after 260*tbase, '1' after 300*tbase, '0' after 340*tbase, '0' after 380*tbase, '0' after 420*tbase, '1' after 460*tbase; --0b00010000

  tb_gpio_pins_in <= "0",
    "1" after 500*tbase,
    "0" after 1100*tbase;

  tb_spi_miso <= '0',
    '0' after 8821*tbase, '0' after 9863*tbase, '1' after 10905*tbase, '1' after 11947*tbase, '0' after 12989*tbase, '0' after 14031*tbase, '0' after 15073*tbase, '0' after 16115*tbase; --0x30;

  tb_i2c_sda_no_pullup <= 'Z',
    '0' after 10748*tbase, 'Z' after 10848*tbase, --ACK ADR
    '0' after 11648*tbase, 'Z' after 11748*tbase, --ACK DATA
    '0' after 12648*tbase, 'Z' after 12748*tbase, --ACK ADR
    '0' after 12748*tbase, '0' after 12848*tbase, 'H' after 12948*tbase, 'H' after 13048*tbase, '0' after 13148*tbase, '0' after 13248*tbase, '0' after 13348*tbase, 'H' after 13448*tbase; -- DATA (0x31)
  
  tb_sram_data_no_pullup <= (others => 'Z'),
    x"3F" after 12054*tbase, (others=>'Z') after 12056*tbase;

  tb_exp_tx_pin_host <= 'U', '1' after 3*tbase,
    '0' after 28*tbase, '0' after 38*tbase, '0' after 48*tbase, '0' after 58*tbase, '0' after 68*tbase, '0' after 78*tbase, '0' after 88*tbase, '0' after 98*tbase, '0' after 108*tbase, '0' after 118*tbase, '1' after 128*tbase, --0b00000000 (reset Unit - was reseted - unit)
    '0' after 138*tbase, '1' after 148*tbase, '1' after 158*tbase, '1' after 168*tbase, '1' after 178*tbase, '1' after 188*tbase, '1' after 198*tbase, '1' after 208*tbase, '1' after 218*tbase, '0' after 228*tbase, '1' after 238*tbase, --0b11111111 (reset Unit - was reseted - data)
    '0' after 338*tbase, '0' after 348*tbase, '0' after 358*tbase, '1' after 368*tbase, '0' after 378*tbase, '0' after 388*tbase, '0' after 398*tbase, '0' after 408*tbase, '0' after 418*tbase, '1' after 428*tbase, '1' after 438*tbase, --0b00000100 (get GPIO data - unit) (0x04)
    '0' after 448*tbase, '0' after 458*tbase, '0' after 468*tbase, '0' after 478*tbase, '0' after 488*tbase, '0' after 498*tbase, '0' after 508*tbase, '0' after 518*tbase, '0' after 528*tbase, '0' after 538*tbase, '1' after 548*tbase, --0b00000000 (get GPIO data - data) (0x00)
    '0' after 558*tbase, '1' after 568*tbase, '1' after 578*tbase, '0' after 588*tbase, '0' after 598*tbase, '0' after 608*tbase, '0' after 618*tbase, '0' after 628*tbase, '0' after 638*tbase, '0' after 648*tbase, '1' after 658*tbase, --0b00000011 (UART in - unit) (0x03)
    '0' after 668*tbase, '0' after 678*tbase, '0' after 688*tbase, '0' after 698*tbase, '0' after 708*tbase, '1' after 718*tbase, '0' after 728*tbase, '0' after 738*tbase, '0' after 748*tbase, '1' after 758*tbase, '1' after 768*tbase, --0b00010000 (UART in - data) (0x10)
    '0' after 778*tbase, '0' after 788*tbase, '0' after 798*tbase, '1' after 808*tbase, '0' after 818*tbase, '0' after 828*tbase, '0' after 838*tbase, '0' after 848*tbase, '0' after 858*tbase, '1' after 868*tbase, '1' after 878*tbase, --0b00000100 (GPIO interrupt - unit) (0x04)
    '0' after 888*tbase, '1' after 898*tbase, '0' after 908*tbase, '0' after 918*tbase, '0' after 928*tbase, '0' after 938*tbase, '0' after 948*tbase, '0' after 958*tbase, '0' after 968*tbase, '1' after 978*tbase, '1' after 988*tbase, --0b00000000 (GPIO interrupt - data) (0x01)
    '0' after 1118*tbase, '0' after 1128*tbase, '0' after 1138*tbase, '1' after 1148*tbase, '0' after 1158*tbase, '0' after 1168*tbase, '0' after 1178*tbase, '0' after 1188*tbase, '0' after 1198*tbase, '1' after 1208*tbase, '1' after 1218*tbase, --0b00000100 (GPIO interrupt - unit) (0x04)
    '0' after 1228*tbase, '0' after 1238*tbase, '0' after 1248*tbase, '0' after 1258*tbase, '0' after 1268*tbase, '0' after 1278*tbase, '0' after 1288*tbase, '0' after 1298*tbase, '0' after 1308*tbase, '0' after 1318*tbase, '1' after 1328*tbase, --0b00000000 (GPIO interrupt - data) (0x00)
    '0' after 3428*tbase, '1' after 3438*tbase, '0' after 3448*tbase, '1' after 3458*tbase, '0' after 3468*tbase, '0' after 3478*tbase, '0' after 3488*tbase, '0' after 3488*tbase, '0' after 3508*tbase, '0' after 3518*tbase, '1' after 3528*tbase, --0b00000101 (Timer interrupt - unit) (0x05)
    '0' after 3538*tbase, '1' after 3548*tbase, '1' after 3558*tbase, '1' after 3568*tbase, '1' after 3578*tbase, '1' after 3588*tbase, '1' after 3598*tbase, '1' after 3608*tbase, '1' after 3618*tbase, '0' after 3628*tbase, '1' after 3638*tbase, --0b11111111 (Timer interrupt - data) (0xFF)
    '0' after 8247*tbase, '0' after 8257*tbase, '0' after 8267*tbase, '0' after 8277*tbase, '0' after 8287*tbase, '0' after 8297*tbase, '0' after 8307*tbase, '0' after 8317*tbase, '0' after 8327*tbase, '0' after 8337*tbase, '1' after 8347*tbase, --0b00000000 (Reset unit - unit) (0x00)
    '0' after 8357*tbase, '1' after 8367*tbase, '1' after 8377*tbase, '1' after 8387*tbase, '1' after 8397*tbase, '1' after 8407*tbase, '1' after 8417*tbase, '1' after 8427*tbase, '1' after 8437*tbase, '0' after 8447*tbase, '1' after 8457*tbase, --0b11111111 (Reset unit - data) (0xFF)
    '0' after 8537*tbase, '0' after 8547*tbase, '1' after 8557*tbase, '0' after 8567*tbase, '0' after 8577*tbase, '0' after 8587*tbase, '0' after 8597*tbase, '0' after 8607*tbase, '0' after 8617*tbase, '1' after 8627*tbase, '1' after 8637*tbase, --0b00000010 (ACK unit - unit) (0x02)
    '0' after 8647*tbase, '1' after 8657*tbase, '1' after 8667*tbase, '1' after 8677*tbase, '1' after 8687*tbase, '1' after 8697*tbase, '1' after 8707*tbase, '1' after 8717*tbase, '1' after 8727*tbase, '0' after 8737*tbase, '1' after 8747*tbase, --0b11111111 (ACK unit - data) (0xFF)
    '0' after 8837*tbase, '0' after 8847*tbase, '1' after 8857*tbase, '0' after 8867*tbase, '0' after 8877*tbase, '0' after 8887*tbase, '0' after 8897*tbase, '0' after 8907*tbase, '0' after 8917*tbase, '1' after 8927*tbase, '1' after 8937*tbase, --0b00000010 (ACK unit - unit) (0x02)
    '0' after 8947*tbase, '1' after 8957*tbase, '0' after 8967*tbase, '1' after 8977*tbase, '0' after 8987*tbase, '0' after 8997*tbase, '1' after 9007*tbase, '0' after 9017*tbase, '1' after 9027*tbase, '0' after 9037*tbase, '1' after 9047*tbase, --0b10100101 (ACK unit - data) (0xA5)
    '0' after 9137*tbase, '0' after 9147*tbase, '1' after 9157*tbase, '0' after 9167*tbase, '0' after 9177*tbase, '0' after 9187*tbase, '0' after 9197*tbase, '0' after 9207*tbase, '0' after 9217*tbase, '1' after 9227*tbase, '1' after 9237*tbase, --0b00000010 (ACK unit - unit) (0x02)
    '0' after 9247*tbase, '0' after 9257*tbase, '0' after 9267*tbase, '0' after 9277*tbase, '0' after 9287*tbase, '0' after 9297*tbase, '0' after 9307*tbase, '0' after 9317*tbase, '0' after 9327*tbase, '0' after 9337*tbase, '1' after 9347*tbase, --0b00000000 (ACK unit - data) (0x00)
    '0' after 12077*tbase, '0' after 12087*tbase, '0' after 12097*tbase, '0' after 12107*tbase, '1' after 12117*tbase, '0' after 12127*tbase, '0' after 12137*tbase, '0' after 12147*tbase, '0' after 12157*tbase, '1' after 12167*tbase, '1' after 12177*tbase, --0b00001000 (SRAM unit - unit) (0x08)
    '0' after 12187*tbase, '1' after 12197*tbase, '1' after 12207*tbase, '1' after 12217*tbase, '1' after 12227*tbase, '1' after 12237*tbase, '1' after 12247*tbase, '0' after 12257*tbase, '0' after 12267*tbase, '0' after 12277*tbase, '1' after 12287*tbase, --0b00111111 (SRAM unit - data) (0x3F)
    '0' after 13517*tbase, '1' after 13527*tbase, '1' after 13537*tbase, '1' after 13547*tbase, '0' after 13557*tbase, '0' after 13567*tbase, '0' after 13577*tbase, '0' after 13587*tbase, '0' after 13597*tbase, '1' after 13607*tbase, '1' after 13617*tbase, --0b00000111 (I2C unit - unit) (0x07)
    '0' after 13627*tbase, 'H' after 13637*tbase, '0' after 13647*tbase, '0' after 13657*tbase, '0' after 13667*tbase, 'H' after 13677*tbase, 'H' after 13687*tbase, '0' after 13697*tbase, '0' after 13707*tbase, '1' after 13717*tbase, '1' after 13727*tbase, --0b00110001 (I2C unit - data) (0x31)
    '0' after 16657*tbase, '0' after 16667*tbase, '1' after 16677*tbase, '1' after 16687*tbase, '0' after 16697*tbase, '0' after 16707*tbase, '0' after 16717*tbase, '0' after 16727*tbase, '0' after 16737*tbase, '0' after 16747*tbase, '1' after 16757*tbase, --0b00000110 (SPI unit - unit) (0x06)
    '0' after 16767*tbase, '0' after 16777*tbase, '0' after 16787*tbase, '0' after 16797*tbase, '0' after 16807*tbase, '1' after 16817*tbase, '1' after 16827*tbase, '0' after 16837*tbase, '0' after 16847*tbase, '0' after 16857*tbase, '1' after 16867*tbase; --0b00110000 (SPI unit - data) (0x30)

  tb_exp_tx_pin_a <= 'U', '1' after 3*tbase,
    '0' after 1183*tbase, '1' after 1223*tbase, '0' after 1263*tbase, '1' after 1303*tbase, '1' after 1343*tbase, '1' after 1383*tbase, '1' after 1423*tbase, '1' after 1463*tbase, '0' after 1503*tbase, '1' after 1543*tbase, --0b01111101 (0x7D)
    '0' after 1583*tbase, '1' after 1623*tbase, '0' after 1663*tbase, '0' after 1703*tbase, '0' after 1743*tbase, '1' after 1783*tbase, '0' after 1823*tbase, '1' after 1863*tbase, '0' after 1903*tbase, '1' after 1943*tbase, --0b01010001 (0x51)
    -- Hello World UART stress test
    '0' after 3863*tbase, '0' after 3903*tbase, '0' after 3943*tbase, '0' after 3983*tbase, '1' after 4023*tbase, '0' after 4063*tbase, '0' after 4103*tbase, '1' after 4143*tbase, '0' after 4183*tbase, '1' after 4223*tbase, -- 'H' (0x48 = 0b01001000)
    '0' after 4263*tbase, '1' after 4303*tbase, '0' after 4343*tbase, '0' after 4383*tbase, '0' after 4423*tbase, '0' after 4463*tbase, '1' after 4503*tbase, '1' after 4543*tbase, '0' after 4583*tbase, '1' after 4623*tbase, -- 'a' (0x61 = 0b01100001)
    '0' after 4663*tbase, '0' after 4703*tbase, '0' after 4743*tbase, '1' after 4783*tbase, '1' after 4823*tbase, '0' after 4863*tbase, '1' after 4903*tbase, '1' after 4943*tbase, '0' after 4983*tbase, '1' after 5023*tbase, -- 'l' (0x6C = 0b01101100)
    '0' after 5063*tbase, '0' after 5103*tbase, '0' after 5143*tbase, '1' after 5183*tbase, '1' after 5223*tbase, '0' after 5263*tbase, '1' after 5303*tbase, '1' after 5343*tbase, '0' after 5383*tbase, '1' after 5423*tbase, -- 'l' (0x6C = 0b01101100)
    '0' after 5463*tbase, '1' after 5503*tbase, '1' after 5543*tbase, '1' after 5583*tbase, '1' after 5623*tbase, '0' after 5663*tbase, '1' after 5703*tbase, '1' after 5743*tbase, '0' after 5783*tbase, '1' after 5823*tbase, -- 'o' (0x6F = 0b01101111)
    '0' after 5863*tbase, '0' after 5903*tbase, '0' after 5943*tbase, '0' after 5983*tbase, '0' after 6023*tbase, '0' after 6063*tbase, '1' after 6103*tbase, '0' after 6143*tbase, '0' after 6183*tbase, '1' after 6223*tbase, -- ' ' (0x20 = 0b00100000)
    '0' after 6263*tbase, '1' after 6303*tbase, '1' after 6343*tbase, '1' after 6383*tbase, '0' after 6423*tbase, '1' after 6463*tbase, '0' after 6503*tbase, '1' after 6543*tbase, '0' after 6583*tbase, '1' after 6623*tbase, -- 'W' (0x57 = 0b01010111)
    '0' after 6663*tbase, '1' after 6703*tbase, '0' after 6743*tbase, '1' after 6783*tbase, '0' after 6823*tbase, '0' after 6863*tbase, '1' after 6903*tbase, '1' after 6943*tbase, '0' after 6983*tbase, '1' after 7023*tbase, -- 'e' (0x65 = 0b01100101)
    '0' after 7063*tbase, '0' after 7103*tbase, '0' after 7143*tbase, '1' after 7183*tbase, '1' after 7223*tbase, '0' after 7263*tbase, '1' after 7303*tbase, '1' after 7343*tbase, '0' after 7383*tbase, '1' after 7423*tbase, -- 'l' (0x6C = 0b01101100)
    '0' after 7463*tbase, '0' after 7503*tbase, '0' after 7543*tbase, '1' after 7583*tbase, '0' after 7623*tbase, '1' after 7663*tbase, '1' after 7703*tbase, '1' after 7743*tbase, '0' after 7783*tbase, '1' after 7823*tbase; -- 't' (0x74 = 0b01110100)

  tb_exp_gpio_pins_out <= "UU", "00" after 3*tbase,
    "10" after 722*tbase,
    "00" after 8222*tbase;

  tb_exp_spi_sck <= 'U', '0' after 3*tbase,
    '1' after 9345*tbase, '0' after 9866*tbase,
    '1' after 10387*tbase, '0' after 10908*tbase,
    '1' after 11429*tbase, '0' after 11950*tbase,
    '1' after 12471*tbase, '0' after 12992*tbase,
    '1' after 13513*tbase, '0' after 14034*tbase,
    '1' after 14555*tbase, '0' after 15076*tbase,
    '1' after 15597*tbase, '0' after 16118*tbase,
    '1' after 16639*tbase, '0' after 17160*tbase;

  tb_exp_spi_cs <= "1",
    "0" after 8823*tbase, "1" after 17161*tbase;

  tb_exp_spi_mosi <= '0',
    '1' after 8824*tbase, '0' after 9866*tbase, '1' after 10908*tbase, '0' after 11950*tbase, '0' after 12992*tbase, '1' after 14034*tbase, '0' after 15076*tbase, '1' after 16118*tbase, '0' after 17160*tbase;

  tb_exp_i2c_sda <= 'H',
    '0' after 9898*tbase, --START
    '0' after 9948*tbase, '0' after 10048*tbase, '0' after 10148*tbase, '0' after 10248*tbase, '0' after 10348*tbase, '0' after 10448*tbase, 'H' after 10548*tbase, '0' after 10648*tbase, -- ADR+RW (0x02)
    '0' after 10748*tbase, --ACK
    'H' after 10848*tbase, 'H' after 10948*tbase, 'H' after 11048*tbase, 'H' after 11148*tbase, '0' after 11248*tbase, '0' after 11348*tbase, '0' after 11448*tbase, '0' after 11548*tbase, -- DATA (0xF0)
    '0' after 11648*tbase, --ACK
    'H' after 11748*tbase, --RS_PREP
    '0' after 11798*tbase, -- RS (Repeated Start)
    '0' after 11848*tbase, '0' after 11948*tbase, '0' after 12048*tbase, '0' after 12148*tbase, '0' after 12248*tbase, '0' after 12348*tbase, 'H' after 12448*tbase, 'H' after 12548*tbase, -- ADR+RW (0x03)
    '0' after 12648*tbase, --ACK
    '0' after 12748*tbase, '0' after 12848*tbase, 'H' after 12948*tbase, 'H' after 13048*tbase, '0' after 13148*tbase, '0' after 13248*tbase, '0' after 13348*tbase, 'H' after 13448*tbase, -- DATA (0x31)
    'H' after 13548*tbase, --NACK (Recv end)
    '0' after 13648*tbase, --STOP_PREP
    'H' after 13698*tbase; --STOP;

  tb_exp_sram_data <= (others=>'H'),
    x"3F" after 11744*tbase, (others=>'H') after 11746*tbase,
    x"3F" after 12054*tbase, (others=>'H') after 12056*tbase;

  tb_exp_sram_adr <= (others=>'U'), (others=>'0') after 1*tbase,
    "0010000111111110000" after 11742*tbase, (others=>'0') after 11746*tbase,
    "0010000111111110000" after 12052*tbase, (others=>'0') after 12055*tbase;

  tb_exp_sram_cen <= '1',
    '0' after 11742*tbase, '1' after 11746*tbase, -- Write
    '0' after 12052*tbase, '1' after 12055*tbase; -- Read
    

  tb_exp_sram_oen <= '1',
    '1' after 11742*tbase, '1' after 11746*tbase, -- Write
    '0' after 12052*tbase, '1' after 12055*tbase; -- Read

  tb_exp_sram_wen <= '1',
    '0' after 11742*tbase, '1' after 11746*tbase, -- Write
    '1' after 12052*tbase, '1' after 12055*tbase; -- Read

  tb_error <= '0' when 
    (tb_exp_tx_pin_host = tb_tx_pin_host)
    and (tb_exp_tx_pin_a = tb_tx_pin_a)
    and (tb_exp_gpio_pins_out = tb_gpio_pins_out) 
    and (tb_exp_spi_sck = tb_spi_sck)
    and (tb_exp_spi_cs = tb_spi_cs)
    and (tb_exp_spi_mosi = tb_spi_mosi)
    and (tb_exp_i2c_scl = tb_i2c_scl)
    and (tb_exp_i2c_sda = tb_i2c_sda)
    and (tb_exp_sram_adr = tb_sram_adr)
    and (tb_exp_sram_data = tb_sram_data)
    and (tb_exp_sram_cen = tb_sram_cen)
    and (tb_exp_sram_oen = tb_sram_oen)
    and (tb_exp_sram_wen = tb_sram_wen) else '1';

end TESTBENCH;