--! @file
--! @brief Example usage top-level entity.
--! @details Example for connecting units with the ExtPack_Management.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.UnitDataArray_Type_PKG.ALL;

--! Top level entity example of ExtPack to show an usage example of the different components and there connection.
--! @details Also used to have a base for testing the whole ExtPack system.
entity Main_Unit is
  Generic(
    FPGA_FREQ : integer := 12000000; --! Frequency of the FPGA @note Condition: Needs to satisfy the conditions of all used units.
    HOST_BAUD : integer := 1000000; --! The BAUD rate used by the host.
    HOST_DATA_BITS : integer := 8; --! The data bits per UART package to/from the host. @note Condition: >= 8 (2 bit access mode, 6 bit unit numbers) and HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15
    HOST_STOP_BITS : integer := 1; --! The amount of stop bits per UART package to/from the host. @note Condition: HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15
    HOST_PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity (of UART package to/from the host) @note Condition: HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15
    HOST_PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity (of UART package to/from the host)
  );
  Port ( 
    --------------- EXTPACK PORTS ---------------
    clk : in STD_LOGIC; --! The clock input pin.
    rst : in STD_LOGIC; --! The reset input pin.
    tx_pin_host : out std_logic; --! The TX UART pin to the host.
    rx_pin_host : in std_logic; --! The RX UART pin for the host.
    ----------------- UNIT PORTS -----------------
    tx_pin_a : out std_logic; --! The TX UART pin to the UART partner of UART_UNIT (unit 3).
    rx_pin_a : in std_logic; --! The RX UART pin for the UART partner of UART_UNIT (unit 3).
    gpio_pins_in : in STD_LOGIC_VECTOR (0 downto 0); --! The GPIO input pins of the GPIO_UNIT (unit 4).
    gpio_pins_out : out STD_LOGIC_VECTOR (1 downto 0); --! The GPIO output pins of the GPIO_UNIT (unit 4).
    spi_sck : out std_logic; --! The SCK pin of the SPI_UNIT (unit 6).
    spi_cs : out std_logic_vector(0 downto 0); --! The CS pin(s) of the SPI_UNIT (unit 6).
    spi_mosi : out std_logic; --! The MOSI pin of the SPI_UNIT (unit 6).
    spi_miso : in std_logic; --! The MISO pin of the SPI_UNIT (unit 6).
    i2c_scl : inout std_logic; --! The SCL pin of the I2C_UNIT (unit 7).
    i2c_sda : inout std_logic; --! The SDA pin of the I2C_UNIT (unit 7).
    sram_adr : out std_logic_vector(18 downto 0); --! The address pins of the SRAM_UNIT (unit 8).
    sram_data : inout std_logic_vector(7 downto 0); --! The data pins of the SRAM_UNIT (unit 8).
    sram_oen : out std_logic := '1'; --! The not output enable pin of the SRAM_UNIT (unit 8).
    sram_cen : out std_logic := '1'; --! The not chip enable pin of the SRAM_UNIT (unit 8).
    sram_wen : out std_logic := '1' --! The not write enable pin of the SRAM_UNIT (unit 8).
  );
end Main_Unit;

--! Architecture implementing the usage example.
architecture Behavioral of Main_Unit is
  --! Component declaration for UART_Wrapper
  component UART_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0;
      PARITY_MODE : integer := 0 
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
  --! Component declaration for SPI_Wrapper
  component SPI_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      IN_FREQ_HZ : integer := 12000000;
      SPI_FREQ_HZ : integer := 9600;
      AMOUNT_SLAVES : integer := 1;
      SPI_MODE : integer := 0;
      LEAST_SIG_BIT_FIRST : integer := 0;
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
  --! Component declaration for I2C_Wrapper
  component I2C_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
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
  --! Component declaration for GPIO_Wrapper
  component GPIO_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      IN_PINS : integer := 8;
      OUT_PINS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
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
  --! Component declaration for Timer_Wrapper
  component Timer_Wrapper
    generic (
      HOST_DATA_BITS : integer := 8;
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000
    );
    port (
      clk, rst         : in  STD_LOGIC;
      write_en         : in  std_logic;
      access_mode      : in  std_logic_vector(1 downto 0);
      unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      unit_data_out    : out STD_LOGIC_VECTOR(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done   : in  std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0'
    );
  end component;
  --! Component declaration for ISSI_IS61WV5128BLL_SRAM_Wrapper
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
  --! Component declaration for IO_Sync
  component IO_Sync
    Port (
      clk, rst : in std_logic;
      async_in : in std_logic;
      sync_out : out std_logic := '0'
    );
  end component;
  --! Component declaration for IO_Sync_Vector
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
  --! Component declaration for ExtPack_Management
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

  --! @brief Subdata type for unit data used for outputs of the units to give the data to send to the scheduler. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  --! @details Array of std_logic_vector with a width of 14 bits used to be able to use this array for the maximum length of UART packages possible.
  subtype unit_data_array_t is unit_data_array(63 downto 3);

  --! @brief Enable signal vector for the unit input (received data from the host). 
  --! @details The n-th bit addresses the n-th unit. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  signal unit_en : std_logic_vector(63 downto 3) := (others => '0');

  --! The access mode of the received command from the host.
  signal decoded_access_mode : std_logic_vector(1 downto 0) := (others => '0');

  --! The unit data of the received command from the host.
  signal unit_data_received : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');

  --! @brief The output data of the units.
  --! @details The n-th bit addresses the n-th unit. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  signal unit_data_send : unit_data_array_t := (others => (others => '0'));

  --! @brief The schedule requests of the units. Enable signals for the units output data.
  --! @details The n-th bit addresses the n-th unit and therefore the n-th unit output/send data. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  signal unit_scheduler_wanted : std_logic_vector(63 downto 3);

  --! @brief The schedule acknowledge for the units. Acknowledges that the data was processed and sent.
  --! @details The n-th bit addresses the n-th unit. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  signal unit_scheduler_done : std_logic_vector(63 downto 3);

  --! @brief Indicators for processing errors in the units in the direction of processing data to the host. (Sending commands to host)
  --! @details The n-th bit of the vector addresses the n-th unit. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  signal error_to_host : std_logic_vector(63 downto 3) := (others => '0');

  --! @brief Indicators for processing errors in the units in the direction of processing data from the host. (Receiving commands from host)
  --! @details The n-th bit of the vector addresses the n-th unit. Only for units 3 and above as 0...2 are already implemented in ExtPack_Management.
  signal error_from_host : std_logic_vector(63 downto 3) := (others => '0');

  --! The reset signal modified by the Reset_Unit to combine hardware reset with software reset.
  signal rst_ext_pack : std_logic := '0';

  -- IO_Sync

  --! Synchronized hardware reset signal.
  signal rst_sync : std_logic;

  --! Synchronized RX from host pin signal.
  signal rx_pin_host_sync : std_logic;

  ----------- UNIT SYNC SIGNALS ----------

  --! Synchronized RX from UART_UNIT (unit 3) partner pin signal.
  signal rx_pin_a_sync : std_logic;

  --! Synchronized GPIO input pin signals of GPIO_Unit (unit 4).
  signal gpio_pins_in_sync : std_logic_vector(0 downto 0);

  --! Synchronized MISO signal of SPI_UNIT (unit 6)
  signal spi_miso_sync : std_logic;

  ----------- SYNC SIGNALS END -----------
  
begin

  --! Synchronization of the hardware reset pin signal.
  SYNC_RST: IO_Sync port map(clk, '0', rst, rst_sync); -- No rst as it could conflict with syncing the rst signal
  --! Synchronizatoion of the host RX pin signal.
  SYNC_UART_HOST: IO_Sync port map(clk, rst_ext_pack, rx_pin_host, rx_pin_host_sync);

  -------------- UNIT SYNC ---------------
  --! Synchronization of the RX pin of UART_UNIT (unit 3).
  SYNC_U03_UART: IO_Sync port map(clk, rst_ext_pack, rx_pin_a, rx_pin_a_sync);
  --! Synchronization of GPIO input pins of GPIO_UNIT (unit 4).
  SYNC_U04_GPIO: IO_Sync_Vector generic map(1) port map(clk, rst_ext_pack, gpio_pins_in, gpio_pins_in_sync);
  --! Synchronization of the MISO pin of SPI_UNIT (unit 6).
  SYNC_U06_SPI: IO_Sync port map(clk, rst_ext_pack, spi_miso, spi_miso_sync);
  -------------- SYNC END ----------------

  --! Manages the communication with the host and manages the special units.
  EXT_PACK_MANAGER: ExtPack_Management generic map(FPGA_FREQ, HOST_BAUD, HOST_DATA_BITS, HOST_STOP_BITS, HOST_PARITY_ACTIVE, HOST_PARITY_MODE) port map(clk, rst_sync, unit_en, decoded_access_mode, unit_data_received, unit_data_send, unit_scheduler_wanted, unit_scheduler_done, error_to_host, error_from_host, rx_pin_host_sync, tx_pin_host, rst_ext_pack);

 ------------- CUSTOM UNITS --------------
  --! Unit 3 - UART_Unit implemented via UART_Wrapper.
  U03_UART: UART_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 250000, 8, 1, 0, 0) port map(clk, rst_ext_pack, unit_en(3), decoded_access_mode, unit_data_received, unit_data_send(3), unit_scheduler_wanted(3), unit_scheduler_done(3), error_to_host(3), error_from_host(3), tx_pin_a, rx_pin_a_sync);
  --! Unit 4 - GPIO_Unit implemented via GPIO_Wrapper.
  U04_GPIO: GPIO_Wrapper generic map(HOST_DATA_BITS, 1, 2) port map(clk, rst_ext_pack, unit_en(4), decoded_access_mode, unit_data_received, unit_data_send(4), unit_scheduler_wanted(4), unit_scheduler_done(4), error_to_host(4), error_from_host(4), gpio_pins_in_sync, gpio_pins_out);
  --! Unit 5 - Timer_Unit implemented via Timer_Wrapper.
  U05_TIME: Timer_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst_ext_pack, unit_en(5), decoded_access_mode, unit_data_received, unit_data_send(5), unit_scheduler_wanted(5), unit_scheduler_done(5), error_to_host(5), error_from_host(5));
  --! Unit 6 - SPI_Unit implemented via SPI_Wrapper.
  U06_SPI: SPI_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 9600, 1, 0, 0, 8) port map(clk, rst_ext_pack, unit_en(6), decoded_access_mode, unit_data_received, unit_data_send(6), unit_scheduler_wanted(6), unit_scheduler_done(6), error_to_host(6), error_from_host(6), spi_sck, spi_cs, spi_mosi, spi_miso_sync);
  --! Unit 7 - I2C_Unit implemented via I2C_Wrapper.
  U07_I2C: I2C_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 100000) port map(clk, rst_ext_pack, unit_en(7), decoded_access_mode, unit_data_received, unit_data_send(7), unit_scheduler_wanted(7), unit_scheduler_done(7), error_to_host(7), error_from_host(7), i2c_scl, i2c_sda);
  --! Unit 8 - ISSI_IS61WV5128BLL_SRAM_Unit implemented via ISSI_IS61WV5128BLL_SRAM_Wrapper.
  U08_RAM: ISSI_IS61WV5128BLL_SRAM_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 8) port map(clk, rst_ext_pack, unit_en(8), decoded_access_mode, unit_data_received, unit_data_send(8), unit_scheduler_wanted(8), unit_scheduler_done(8), error_to_host(8), error_from_host(8), sram_adr, sram_data, sram_oen, sram_cen, sram_wen);
  -------------- UNITS END ----------------

end Behavioral;

-- TODO: TB für ExtPack_Management
-- TODO: Rename signals if necessary