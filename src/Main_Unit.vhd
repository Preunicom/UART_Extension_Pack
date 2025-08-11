--! @file
--! @brief Example usage top-level entity.
--! @details Example for connecting units with the ExtPack_Management.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.UnitDataArray_Type_PKG.ALL;

entity Main_Unit is
  Generic(
    -- FPGA_FREQ has to be minimum 2*HOST_BAUD if using units which create clock signals
    FPGA_FREQ : integer := 12000000;
    HOST_BAUD : integer := 1000000;
    -- HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15 has to be fullfilled
    -- HOST_DATA_BITS >= 8 has to be fullfilled (64 units (6 bit) + 2 access bits)
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
end Main_Unit;

architecture Behavioral of Main_Unit is
  component UART_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
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
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      TX_pin : out std_logic;
      RX_pin : in std_logic
    );
  end component;
  component SPI_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN_FREQ_HZ has to be minimum 2*SPI_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      SPI_FREQ_HZ : integer := 9600;
      AMOUNT_SLAVES : integer := 1;
      SPI_MODE : integer := 0;
      LEAST_SIG_BIT_FIRST : integer := 0; -- true or false
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      SCK : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      MOSI : out std_logic;
      MISO : in std_logic
    );
  end component;
  component I2C_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN_FREQ_HZ has to be minimum 4*I2C_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      I2C_FREQ_HZ : integer := 100000
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      SCL : inout std_logic;
      SDA : inout std_logic
    );
  end component;
  component GPIO_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN/OUT_PINS <= HOST_DATA_BITS has to be fullfilled
      -- IN/OUT_PINS >= 1 has to be fullfilled
      IN_PINS : integer := 8;
      OUT_PINS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
      unit_data_in : in STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out STD_LOGIC_VECTOR(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      gpio_data_in : in STD_LOGIC_VECTOR (IN_PINS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (OUT_PINS-1 downto 0)
    );
  end component;
  component Timer_Wrapper
    generic (
      HOST_DATA_BITS : integer := 8;
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000
    );
    port (
      clk, rst         : in  STD_LOGIC;
      write_en         : in  std_logic;
      access_mode      : in  std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
      unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      unit_data_out    : out STD_LOGIC_VECTOR(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done   : in  std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0'
    );
  end component;
  component ISSI_IS61WV5128BLL_SRAM_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      IN_FREQ : integer := 12000000;
      ACCESS_TIME_NS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0) := (others => '0');
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      sram_adr : out std_logic_vector(18 downto 0);
      sram_data : inout std_logic_vector(7 downto 0);
      sram_oen : out std_logic := '1';
      sram_cen : out std_logic := '1';
      sram_wen : out std_logic := '1'
    );
  end component;
  component IO_Sync
    Port (
      clk, rst : in std_logic;
      async_in : in std_logic;
      sync_out : out std_logic := '0'
    );
  end component;
  component IO_Sync_Vector
    Generic(
      len: integer := 1
    );
    Port (
      clk, rst : in std_logic;
      async_in : in std_logic_vector(len-1 downto 0);
      sync_out : out std_logic_vector(len-1 downto 0) := (others => '0')
    );
  end component;
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
      unit_en : out std_logic_vector(63 downto 3);
      decoded_access_mode : out std_logic_vector(1 downto 0);
      unit_data_received : out std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_send : in unit_data_array;
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

  signal unit_en : std_logic_vector(63 downto 3) := (others => '0');
  signal decoded_access_mode : std_logic_vector(1 downto 0) := (others => '0');
  signal unit_data_received : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_send : unit_data_array_t := (others => (others => '0'));
  signal unit_scheduler_wanted : std_logic_vector(63 downto 3);
  signal unit_scheduler_done : std_logic_vector(63 downto 3);
  signal error_to_host : std_logic_vector(63 downto 3) := (others => '0');
  signal error_from_host : std_logic_vector(63 downto 3) := (others => '0');
  signal rst_ext_pack : std_logic := '0';

  -- IO_Sync
  signal rst_sync : std_logic;
  signal rx_pin_host_sync : std_logic;
  ----------- UNIT SYNC SIGNALS ----------
  signal rx_pin_a_sync : std_logic;
  signal gpio_pins_in_sync : std_logic_vector(0 downto 0);
  signal spi_miso_sync : std_logic;

  ----------- SYNC SIGNALS END -----------
  
begin
  SYNC_RST: IO_Sync port map(clk, '0', rst, rst_sync); -- No rst as it could conflict with syncing the rst signal
  SYNC_UART_HOST: IO_Sync port map(clk, rst_ext_pack, rx_pin_host, rx_pin_host_sync);
  -------------- UNIT SYNC ---------------
  SYNC_U03_UART: IO_Sync port map(clk, rst_ext_pack, rx_pin_a, rx_pin_a_sync);
  SYNC_U04_GPIO: IO_Sync_Vector generic map(1) port map(clk, rst_ext_pack, gpio_pins_in, gpio_pins_in_sync);
  SYNC_U06_SPI: IO_Sync port map(clk, rst_ext_pack, spi_miso, spi_miso_sync);
  -------------- SYNC END ----------------

  EXT_PACK_COMM: ExtPack_Management generic map(FPGA_FREQ, HOST_BAUD, HOST_DATA_BITS, HOST_STOP_BITS, HOST_PARITY_ACTIVE, HOST_PARITY_MODE) port map(clk, rst_sync, unit_en, decoded_access_mode, unit_data_received, unit_data_send, unit_scheduler_wanted, unit_scheduler_done, error_to_host, error_from_host, rx_pin_host_sync, tx_pin_host, rst_ext_pack);

 ------------- CUSTOM UNITS --------------
  U03_UART: UART_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 250000, 8, 1, 0, 0) port map(clk, rst_ext_pack, unit_en(3), decoded_access_mode, unit_data_received, unit_data_send(3), unit_scheduler_wanted(3), unit_scheduler_done(3), error_to_host(3), error_from_host(3), tx_pin_a, rx_pin_a_sync);
  U04_GPIO: GPIO_Wrapper generic map(HOST_DATA_BITS, 1, 2) port map(clk, rst_ext_pack, unit_en(4), decoded_access_mode, unit_data_received, unit_data_send(4), unit_scheduler_wanted(4), unit_scheduler_done(4), error_to_host(4), error_from_host(4), gpio_pins_in_sync, gpio_pins_out);
  U05_TIME: Timer_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst_ext_pack, unit_en(5), decoded_access_mode, unit_data_received, unit_data_send(5), unit_scheduler_wanted(5), unit_scheduler_done(5), error_to_host(5), error_from_host(5));
  U06_SPI: SPI_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 9600, 1, 0, 0, 8) port map(clk, rst_ext_pack, unit_en(6), decoded_access_mode, unit_data_received, unit_data_send(6), unit_scheduler_wanted(6), unit_scheduler_done(6), error_to_host(6), error_from_host(6), spi_sck, spi_cs, spi_mosi, spi_miso_sync);
  U07_I2C: I2C_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 100000) port map(clk, rst_ext_pack, unit_en(7), decoded_access_mode, unit_data_received, unit_data_send(7), unit_scheduler_wanted(7), unit_scheduler_done(7), error_to_host(7), error_from_host(7), i2c_scl, i2c_sda);
  U08_RAM: ISSI_IS61WV5128BLL_SRAM_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 8) port map(clk, rst_ext_pack, unit_en(8), decoded_access_mode, unit_data_received, unit_data_send(8), unit_scheduler_wanted(8), unit_scheduler_done(8), error_to_host(8), error_from_host(8), sram_adr, sram_data, sram_oen, sram_cen, sram_wen);

  -------------- UNITS END ----------------

end Behavioral;

-- TODO: Ordnerstruktur in vivado ändern --> Externe Module in gleichen Ordner und gleichen Ordner aufteilen in Topics
-- TODO: Libs nur mit Code in GitHub --> Doxygen entsprechend anpassen
-- TODO: Remove comments in component declaration
-- TODO: TB für ExtPack_Management
-- TODO: NUMERIC_STD verwenden