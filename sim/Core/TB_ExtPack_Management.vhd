library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.UnitDataArray_Type_PKG.ALL;

entity TB_ExtPack_Management is
  Port(
    signal tb_error : out std_logic
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

  tb_send_unit_data <= (others => (others => '0'));

  tb_unit_scheduler_wanted <= (others => '0');

  tb_error_to_host <= (others => '0');

  tb_error_from_host <= (others => '0');

  tb_rx_pin_host_synced <= '1',
    '0' after 410*tbase, '0' after 420*tbase, '0' after 430*tbase, '1' after 440*tbase, '0' after 450*tbase, '0' after 460*tbase, '0' after 470*tbase, '0' after 480*tbase, '0' after 490*tbase, '1' after 500*tbase, '1' after 510*tbase, --00000100 (set GPIO data) (0x04)
    '0' after 610*tbase, '0' after 620*tbase, '1' after 630*tbase, '1' after 640*tbase, '1' after 650*tbase, '1' after 660*tbase, '1' after 670*tbase, '1' after 680*tbase, '1' after 690*tbase, '1' after 700*tbase, '1' after 710*tbase, --0b11111110 (0xFE)
    '0' after 800*tbase, '1' after 860*tbase; -- UART error

  tb_exp_recv_unit_en(63 downto 5) <= (others => 'U'), (others => '0') after 1*tbase;
  tb_exp_recv_unit_en(4) <= 'U', '0' after 1*tbase, '1' after 718*tbase, '0' after 719*tbase;
  tb_exp_recv_unit_en(3) <= 'U', '0' after 1*tbase;

  tb_exp_recv_unit_access_mode <= (others => 'U'), (others => '0') after 1*tbase,
    "00" after 718*tbase;

  tb_exp_recv_unit_data <= (others => 'U'), (others => '0') after 1*tbase,
    x"FE" after 718*tbase;

  tb_exp_unit_scheduler_done <= (others => 'U'), (others => '0') after 1*tbase;

  tb_exp_tx_pin_host <= 'U', '1' after 1*tbase,
    '0' after 26*tbase, '0' after 36*tbase, '0' after 46*tbase, '0' after 56*tbase, '0' after 66*tbase, '0' after 76*tbase, '0' after 86*tbase, '0' after 96*tbase, '0' after 106*tbase, '0' after 116*tbase, '1' after 126*tbase, --0b00000000 (reset Unit - was reseted - unit)
    '0' after 136*tbase, '1' after 146*tbase, '1' after 156*tbase, '1' after 166*tbase, '1' after 176*tbase, '1' after 186*tbase, '1' after 196*tbase, '1' after 206*tbase, '1' after 216*tbase, '0' after 226*tbase, '1' after 236*tbase, --0b11111111 (reset Unit - was reseted - data)
    '0' after 1266*tbase, '1' after 1276*tbase, '0' after 1286*tbase, '0' after 1296*tbase, '0' after 1306*tbase, '0' after 1316*tbase, '0' after 1326*tbase, '0' after 1336*tbase, '0' after 1346*tbase, '1' after 1356*tbase, '1' after 1366*tbase,
    '0' after 1376*tbase, '1' after 1386*tbase, '0' after 1396*tbase, '0' after 1406*tbase, '0' after 1416*tbase, '0' after 1426*tbase, '0' after 1436*tbase, '0' after 1446*tbase, '0' after 1456*tbase, '1' after 1466*tbase, '1' after 1476*tbase;

  tb_exp_rst_system <= '1', '0' after 2*tbase;
  
  tb_error <= '0' when 
    (tb_exp_recv_unit_en = tb_recv_unit_en)
    and (tb_exp_recv_unit_access_mode = tb_recv_unit_access_mode)
    and (tb_exp_recv_unit_data = tb_recv_unit_data)
    and (tb_exp_unit_scheduler_done = tb_unit_scheduler_done)
    and (tb_exp_tx_pin_host = tb_tx_pin_host)
    and (tb_exp_rst_system = tb_rst_system) else '1';

end TESTBENCH;
