--! @file
--! @brief Testbench for the ExtPack_Management
--! @details
--! This file contains the testbench for the ExtPack_Management entity.  
--! It tests:
--! - unit data send request and receive data
--! - error send request
--! - UART error input with error sending
--! - send reset
--! - ACK enable and disable

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.UnitDataArray_Type_PKG.ALL;

entity TB_ExtPack_Management is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_ExtPack_Management;

architecture TESTBENCH of TB_ExtPack_Management is
  component ExtPack_Management
    Generic(
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000;
      HOST_DATA_BITS : integer := 8;
      HOST_STOP_BITS : integer := 1;
      HOST_PARITY_ACTIVE : integer := 0;
      HOST_PARITY_MODE : integer := 0
    );
    Port (
      clk : in std_logic;
      rst : in std_logic;
      recv_unit_en : out std_logic_vector(63 downto 3);
      recv_unit_access_mode : out std_logic_vector(1 downto 0);
      recv_unit_data : out std_logic_vector(HOST_DATA_BITS-1 downto 0);
      send_unit_data : in unit_data_array;
      unit_scheduler_wanted : in std_logic_vector(63 downto 3);
      unit_scheduler_done : out std_logic_vector(63 downto 3);
      error_to_host : in std_logic_vector(63 downto 3);
      error_from_host : in std_logic_vector(63 downto 3);
      rx_pin_host_synced : in std_logic;
      tx_pin_host : out std_logic;
      rst_system : out std_logic
    );
  end component;

  subtype unit_data_array_t is unit_data_array(63 downto 3);

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_recv_unit_en, tb_exp_recv_unit_en : std_logic_vector(63 downto 3);
  signal tb_recv_unit_access_mode, tb_exp_recv_unit_access_mode : std_logic_vector(1 downto 0);
  signal tb_recv_unit_data, tb_exp_recv_unit_data : std_logic_vector(7 downto 0);
  signal tb_send_unit_data : unit_data_array_t;
  signal tb_unit_scheduler_wanted : std_logic_vector(63 downto 3);
  signal tb_unit_scheduler_done, tb_exp_unit_scheduler_done : std_logic_vector(63 downto 3);
  signal tb_error_to_host : std_logic_vector(63 downto 3);
  signal tb_error_from_host : std_logic_vector(63 downto 3);
  signal tb_rx_pin_host_synced : std_logic;
  signal tb_tx_pin_host, tb_exp_tx_pin_host : std_logic;
  signal tb_rst_system, tb_exp_rst_system : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: ExtPack_Management generic map(10000000, 1000000, 8, 1, 1, 0) port map(tb_clk, tb_rst, tb_recv_unit_en, tb_recv_unit_access_mode, tb_recv_unit_data, tb_send_unit_data, tb_unit_scheduler_wanted, tb_unit_scheduler_done, tb_error_to_host, tb_error_from_host, tb_rx_pin_host_synced, tb_tx_pin_host, tb_rst_system);

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

  tb_send_unit_data(62 downto 3) <= (others => (others => '0'));
  tb_send_unit_data(63) <= (others => '0'),
    "00000001011000" after 5900*tbase, x"00" after 5904*tbase;

  tb_unit_scheduler_wanted(62 downto 3) <= (others => '0');
  tb_unit_scheduler_wanted(63) <= '0',
    '1' after 5900*tbase, '0' after 5904*tbase;

  tb_error_to_host(62 downto 3) <= (others => '0');
  tb_error_to_host(63) <= '0', 
    '1' after 2500*tbase, '0'after 2501*tbase,
    '1' after 3500*tbase, '0'after 3501*tbase;

  tb_error_from_host(63 downto 36) <= (others => '0');
  tb_error_from_host(34 downto 3) <= (others => '0');
  tb_error_from_host(35) <= '0', 
    '1' after 3000*tbase, '0' after 3001*tbase,
    '1' after 3500*tbase, '0' after 3501*tbase;

  tb_rx_pin_host_synced <= '1',
    '0' after 410*tbase, '0' after 420*tbase, '0' after 430*tbase, '1' after 440*tbase, '0' after 450*tbase, '0' after 460*tbase, '0' after 470*tbase, '0' after 480*tbase, '0' after 490*tbase, '1' after 500*tbase, '1' after 510*tbase, --00000100 (set GPIO data) (0x04)
    '0' after 610*tbase, '0' after 620*tbase, '1' after 630*tbase, '1' after 640*tbase, '1' after 650*tbase, '1' after 660*tbase, '1' after 670*tbase, '1' after 680*tbase, '1' after 690*tbase, '1' after 700*tbase, '1' after 710*tbase, --0b11111110 (0xFE)
    '0' after 800*tbase, '1' after 860*tbase, -- UART error
    '0' after 1500*tbase, '0' after 1510*tbase, '0' after 1520*tbase, '0' after 1530*tbase, '0' after 1540*tbase, '0' after 1550*tbase, '0' after 1560*tbase, '0' after 1570*tbase, '0' after 1580*tbase, '0' after 1590*tbase, '1' after 1600*tbase, --00000000 (Reset ExtPack) (0x00)
    '0' after 1700*tbase, '1' after 1710*tbase, '1' after 1720*tbase, '1' after 1730*tbase, '1' after 1740*tbase, '1' after 1750*tbase, '1' after 1760*tbase, '1' after 1770*tbase, '1' after 1780*tbase, '0' after 1790*tbase, '1' after 1800*tbase, --0b11111111 (0xFF)
    '0' after 4000*tbase, '0' after 4010*tbase, '1' after 4020*tbase, '0' after 4030*tbase, '0' after 4040*tbase, '0' after 4050*tbase, '0' after 4060*tbase, '0' after 4070*tbase, '0' after 4080*tbase, '1' after 4090*tbase, '1' after 4100*tbase, --0b00000010 (ACK enable)
    '0' after 4110*tbase, '1' after 4120*tbase, '1' after 4130*tbase, '1' after 4140*tbase, '1' after 4150*tbase, '1' after 4160*tbase, '1' after 4170*tbase, '1' after 4180*tbase, '1' after 4190*tbase, '0' after 4200*tbase, '1' after 4210*tbase, --0b11111111 (0xFF)
    '0' after 4600*tbase, '0' after 4610*tbase, '1' after 4620*tbase, '0' after 4630*tbase, '0' after 4640*tbase, '0' after 4650*tbase, '0' after 4660*tbase, '0' after 4670*tbase, '0' after 4680*tbase, '1' after 4690*tbase, '1' after 4700*tbase, --0b00000010 (ACK disable)
    '0' after 4710*tbase, '0' after 4720*tbase, '0' after 4730*tbase, '0' after 4740*tbase, '0' after 4750*tbase, '0' after 4760*tbase, '0' after 4770*tbase, '0' after 4780*tbase, '0' after 4790*tbase, '0' after 4800*tbase, '1' after 4810*tbase; --0b00000000 (0x00)
    
  tb_exp_recv_unit_en(63 downto 5) <= (others => 'U'), (others => '0') after 1*tbase;
  tb_exp_recv_unit_en(4) <= 'U', '0' after 1*tbase, '1' after 718*tbase, '0' after 719*tbase;
  tb_exp_recv_unit_en(3) <= 'U', '0' after 1*tbase;

  tb_exp_recv_unit_access_mode <= (others => 'U'), (others => '0') after 1*tbase,
    "00" after 718*tbase;

  tb_exp_recv_unit_data <= (others => 'U'), (others => '0') after 1*tbase,
    x"FE" after 718*tbase,
    x"FF" after 1808*tbase, (others => '0') after 1810*tbase,
    x"FF" after 4218*tbase, (others => '0') after 4818*tbase;

  tb_exp_unit_scheduler_done(62 downto 3) <= (others => 'U'), (others => '0') after 1*tbase;
  tb_exp_unit_scheduler_done(63) <= 'U', '0' after 1*tbase,
    '1' after 5903*tbase, '0' after 5904*tbase;

  tb_exp_tx_pin_host <= 'U', '1' after 1*tbase,
    '0' after 26*tbase, '0' after 36*tbase, '0' after 46*tbase, '0' after 56*tbase, '0' after 66*tbase, '0' after 76*tbase, '0' after 86*tbase, '0' after 96*tbase, '0' after 106*tbase, '0' after 116*tbase, '1' after 126*tbase, -- 0b00000000 (reset Unit - was reseted - unit)
    '0' after 136*tbase, '1' after 146*tbase, '1' after 156*tbase, '1' after 166*tbase, '1' after 176*tbase, '1' after 186*tbase, '1' after 196*tbase, '1' after 206*tbase, '1' after 216*tbase, '0' after 226*tbase, '1' after 236*tbase, -- 0b11111111 (reset Unit - was reseted - data)
    '0' after 1266*tbase, '1' after 1276*tbase, '0' after 1286*tbase, '0' after 1296*tbase, '0' after 1306*tbase, '0' after 1316*tbase, '0' after 1326*tbase, '0' after 1336*tbase, '0' after 1346*tbase, '1' after 1356*tbase, '1' after 1366*tbase, -- 0b00000001 Decoding error - unit number
    '0' after 1376*tbase, '1' after 1386*tbase, '0' after 1396*tbase, '0' after 1406*tbase, '0' after 1416*tbase, '0' after 1426*tbase, '0' after 1436*tbase, '0' after 1446*tbase, '0' after 1456*tbase, '1' after 1466*tbase, '1' after 1476*tbase, -- 0b00000001 Decoding error - data
    '0' after 1835*tbase, '0' after 1845*tbase, '0' after 1855*tbase, '0' after 1865*tbase, '0' after 1875*tbase, '0' after 1885*tbase, '0' after 1895*tbase, '0' after 1905*tbase, '0' after 1915*tbase, '0' after 1925*tbase, '1' after 1935*tbase, -- 0b00000000 (reset Unit - was reseted - unit)
    '0' after 1945*tbase, '1' after 1955*tbase, '1' after 1965*tbase, '1' after 1975*tbase, '1' after 1985*tbase, '1' after 1995*tbase, '1' after 2005*tbase, '1' after 2015*tbase, '1' after 2025*tbase, '0' after 2035*tbase, '1' after 2045*tbase, -- 0b11111111 (reset Unit - was reseted - data)
    '0' after 2525*tbase, '1' after 2535*tbase, '0' after 2545*tbase, '0' after 2555*tbase, '0' after 2565*tbase, '0' after 2575*tbase, '0' after 2585*tbase, '0' after 2595*tbase, '0' after 2605*tbase, '1' after 2615*tbase, '1' after 2625*tbase, -- 0b00000001 (Error Unit - unit number)
    '0' after 2635*tbase, '0' after 2645*tbase, '1' after 2655*tbase, '0' after 2665*tbase, '0' after 2675*tbase, '0' after 2685*tbase, '0' after 2695*tbase, '0' after 2705*tbase, '0' after 2715*tbase, '1' after 2725*tbase, '1' after 2735*tbase, -- 0b11111111 (Error Unit - unit data - error to host)
    '0' after 3025*tbase, '1' after 3035*tbase, '0' after 3045*tbase, '0' after 3055*tbase, '0' after 3065*tbase, '0' after 3075*tbase, '0' after 3085*tbase, '0' after 3095*tbase, '0' after 3105*tbase, '1' after 3115*tbase, '1' after 3125*tbase, -- 0b00000001 (Error Unit - unit number)
    '0' after 3135*tbase, '0' after 3145*tbase, '0' after 3155*tbase, '1' after 3165*tbase, '0' after 3175*tbase, '0' after 3185*tbase, '0' after 3195*tbase, '0' after 3205*tbase, '0' after 3215*tbase, '1' after 3225*tbase, '1' after 3235*tbase, -- 0b11111111 (Error Unit - unit data - error from host)
    '0' after 3525*tbase, '1' after 3535*tbase, '0' after 3545*tbase, '0' after 3555*tbase, '0' after 3565*tbase, '0' after 3575*tbase, '0' after 3585*tbase, '0' after 3595*tbase, '0' after 3605*tbase, '1' after 3615*tbase, '1' after 3625*tbase, -- 0b00000001 (Error Unit - unit number)
    '0' after 3635*tbase, '0' after 3645*tbase, '1' after 3655*tbase, '1' after 3665*tbase, '0' after 3675*tbase, '0' after 3685*tbase, '0' after 3695*tbase, '0' after 3705*tbase, '0' after 3715*tbase, '0' after 3725*tbase, '1' after 3735*tbase, -- 0b11111111 (Error Unit - unit data - error to and from host)
    '0' after 4235*tbase, '0' after 4245*tbase, '1' after 4255*tbase, '0' after 4265*tbase, '0' after 4275*tbase, '0' after 4285*tbase, '0' after 4295*tbase, '0' after 4305*tbase, '0' after 4315*tbase, '1' after 4325*tbase, '1' after 4335*tbase, -- 0b00000010 (ACK Unit - unit number)
    '0' after 4345*tbase, '1' after 4355*tbase, '1' after 4365*tbase, '1' after 4375*tbase, '1' after 4385*tbase, '1' after 4395*tbase, '1' after 4405*tbase, '1' after 4415*tbase, '1' after 4425*tbase, '0' after 4435*tbase, '1' after 4445*tbase, -- 0b11111111 (ACK Unit - unit data - ACK)
    '0' after 4835*tbase, '0' after 4845*tbase, '1' after 4855*tbase, '0' after 4865*tbase, '0' after 4875*tbase, '0' after 4885*tbase, '0' after 4895*tbase, '0' after 4905*tbase, '0' after 4915*tbase, '1' after 4925*tbase, '1' after 4935*tbase, -- 0b00000010 (ACK Unit - unit number)
    '0' after 4945*tbase, '0' after 4955*tbase, '0' after 4965*tbase, '0' after 4975*tbase, '0' after 4985*tbase, '0' after 4995*tbase, '0' after 5005*tbase, '0' after 5015*tbase, '0' after 5025*tbase, '0' after 5035*tbase, '1' after 5045*tbase, -- 0b00000000 (ACK Unit - unit data - ACK)
    '0' after 5915*tbase, '1' after 5925*tbase, '1' after 5935*tbase, '1' after 5945*tbase, '1' after 5955*tbase, '1' after 5965*tbase, '1' after 5975*tbase, '0' after 5985*tbase, '0' after 5995*tbase, '0' after 6005*tbase, '1' after 6015*tbase, -- 0b00111111 (Unit number (unit 63))
    '0' after 6025*tbase, '0' after 6035*tbase, '0' after 6045*tbase, '0' after 6055*tbase, '1' after 6065*tbase, '1' after 6075*tbase, '0' after 6085*tbase, '1' after 6095*tbase, '0' after 6105*tbase, '1' after 6115*tbase, '1' after 6125*tbase; -- 0b01011000 (Unit data (unit 63))

  tb_exp_rst_system <= '1', '0' after 2*tbase,
    '1' after 1809*tbase, '0' after 1810*tbase;
  
  tb_error <= '0' when 
    (tb_exp_recv_unit_en = tb_recv_unit_en)
    and (tb_exp_recv_unit_access_mode = tb_recv_unit_access_mode)
    and (tb_exp_recv_unit_data = tb_recv_unit_data)
    and (tb_exp_unit_scheduler_done = tb_unit_scheduler_done)
    and (tb_exp_tx_pin_host = tb_tx_pin_host)
    and (tb_exp_rst_system = tb_rst_system) else '1';

end TESTBENCH;