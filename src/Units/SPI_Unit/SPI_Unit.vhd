--! @file
--! @brief Top-level SPI unit.
--! @details Coordinates SPI clock management, prescaling, serialization, and deserialization for a configurable number of slaves and data formats.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! \defgroup UNIT ExtPack units
--! @brief Standard units of ExtPack.
--! @{

--! @brief Entity implementing an SPI master unit, instantiating prescaler, clock manager, serializer, and deserializer submodules.\n
--! @details Supports:\n
--! - SPI Mode 0-3\n
--! - LSB and MSB\n
--! - Speeds up to half of FPGA Freq.\n
--! - Theoretically unlimited slaves (depending on available pins of the FPGA)\n
--! - Unlimited data bits per message.
entity SPI_Unit is
--! @}
  Generic (
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz. @note Condition: IN_FREQ_HZ >= 2x SPI_FREQ_HZ
    SPI_FREQ_HZ : integer := 9600; --! Desired SPI clock frequency in Hz.
    AMOUNT_SLAVES : integer := 1; --! Number of connected SPI slave devices.
    DATA_BITS : integer := 8; --! Number of bits per SPI frame.
    SPI_MODE : integer := 0; --! SPI mode (0..3: defines clock polarity and phase).
    LEAST_SIG_BIT_FIRST : integer := 0 --! 0: MSB first; 1: LSB first.
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    SCK : out std_logic; --! SPI clock output.
    send_data : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel data to be sent to SPI bus.
    slave_id : in integer; --! Index of slave device to address.
    write_en : in std_logic; --! Strobe to initiate SPI transmission.
    ready : out std_logic; --! SPI unit ready for next transmission.
    MOSI : out std_logic; --! Master Out Slave In line.
    CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1'); --! Chip select lines (active low).
    received_data : out std_logic_vector(DATA_BITS-1 downto 0); --! Parallel data received from SPI bus.
    new_data_received : out std_logic; --! Pulse: new data available from SPI reception.
    MISO : in std_logic --! Master In Slave Out line.
  );
end SPI_Unit;

--! Architecture connecting SPI prescaler, clock manager, serializers, and deserializers into a complete SPI master interface.
architecture Behavioral of SPI_Unit is
  --! Component declaration for SPI clock manager handling SCK, CS, and ready signalling.
  component SPI_CLK_Manager
    Generic (
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0;
      AMOUNT_SLAVES : integer := 1
    );
    Port (
      clk, rst : in std_logic;
      write_en : in std_logic;
      slave_id : in integer;
      prescaled_falling_edge : in std_logic;
      prescaled_rising_edge : in std_logic;
      prescaler_rst : out std_logic;
      deserializer_clk_en : out std_logic;
      serializer_clk_en : out std_logic;
      SCK : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      ready : out std_logic := '1'
    );
  end component;
  --! Component declaration for prescaler generating SPI clock edges.
  component SPI_Prescaler
    generic (
      -- IN_FREQ_HZ has to be minimum 2*OUT_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0
    );
    port (
      clk, rst      : in  STD_LOGIC;
      clk_prescaled_rising_edge : out STD_LOGIC;
      clk_prescaled_falling_edge : out STD_LOGIC
    );
  end component;
  --! Component declaration for RX buffer storing received SPI data.
  component SPI_Buffer_Register_Deserializer
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      write_en : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      new_data : out std_logic
    );
  end component;
  --! Component declaration for SPI deserializer converting serial MISO data to parallel format.
  component SPI_Deserializer
    Generic(
      DATA_BITS : integer := 8;
      LSB : integer := 0
    );
    Port ( 
      clk, clk_en_prescaled, rst : in std_logic;
      serial_in : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      data_valid : out std_logic
    );
  end component;
  --! Component declaration for TX buffer holding data before serialization.
  component SPI_Buffer_Register_Serializer
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst, write_enable : in std_logic;
      data_in : in std_logic_vector(DATA_BITS-1 downto 0);
      data_not_needed_anymore : in std_logic;
      data_out : out std_logic_vector(DATA_BITS-1 downto 0);
      full : out std_logic
      );
  end component;
  --! Component declaration for SPI serializer converting parallel MOSI data to serial output.
  component SPI_Serializer is
    Generic(
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0;
      LSB : integer := 0 -- true or false
    );
    Port ( 
      clk, clk_en_prescaled, rst, write_enable : in std_logic;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      serial_out : out std_logic := '0';
      buffer_data_saved : out std_logic
    );
  end component;
  --! Rising edge pulse of prescaled SPI clock.
  signal prescaled_clk_rising_edge : std_logic;
  --! Falling edge pulse of prescaled SPI clock.
  signal prescaled_clk_falling_edge : std_logic;
  --! Reset signal for prescaler from clock manager.
  signal prescaler_rst : std_logic := '0';
  --! Combined reset (prescaler reset or global reset).
  signal comb_pres_rst : std_logic := '0';
  --! Parallel data output from deserializer.
  signal deser_data_out : std_logic_vector(DATA_BITS-1 downto 0);
  --! Data valid flag from deserializer.
  signal deser_data_out_valid : std_logic := '0';
  --! Buffer full flag for serializer.
  signal buf_ser_full : std_logic := '1';
  --! Serializer data saved handshake signal.
  signal ser_data_saved : std_logic;
  --! Buffered TX data output to serializer.
  signal buf_ser_data_out : std_logic_vector(DATA_BITS-1 downto 0);
  --! Clock enable for serializer from clock manager.
  signal clk_en_prescaled_serializer : std_logic;
  --! Clock enable for deserializer from clock manager.
  signal clk_en_prescaled_deserializer : std_logic;
begin
  --! Instantiate SPI prescaler.
  PRESCAL: SPI_Prescaler generic map(IN_FREQ_HZ, SPI_FREQ_HZ, DATA_BITS, SPI_MODE) port map(clk, comb_pres_rst, prescaled_clk_rising_edge, prescaled_clk_falling_edge);
  --! Instantiate SPI clock manager.
  CLK_MAN: SPI_CLK_Manager generic map(DATA_BITS, SPI_MODE, AMOUNT_SLAVES) port map(clk, rst, write_en, slave_id, prescaled_clk_falling_edge, prescaled_clk_rising_edge, prescaler_rst, clk_en_prescaled_deserializer, clk_en_prescaled_serializer, SCK, CS, ready);
  --! Instantiate SPI RX buffer.
  BUF_DESER: SPI_Buffer_Register_Deserializer generic map(DATA_BITS) port map(clk, rst, deser_data_out, deser_data_out_valid, received_data, new_data_received);
  --! Instantiate SPI deserializer.
  DESER: SPI_Deserializer generic map(DATA_BITS, LEAST_SIG_BIT_FIRST) port map(clk, clk_en_prescaled_deserializer, rst, MISO, deser_data_out, deser_data_out_valid);
  --! Instantiate SPI TX buffer.
  BUF_SER: SPI_Buffer_Register_Serializer generic map(DATA_BITS) port map(clk, rst, write_en, send_data, ser_data_saved, buf_ser_data_out, buf_ser_full);
  --! Instantiate SPI serializer.
  SER: SPI_Serializer generic map(DATA_BITS, SPI_MODE, LEAST_SIG_BIT_FIRST) port map(clk, clk_en_prescaled_serializer, comb_pres_rst, buf_ser_full, buf_ser_data_out, MOSI, ser_data_saved);

  -- Combine prescaler-specific reset with global reset.
  comb_pres_rst <= prescaler_rst or rst;

end Behavioral;
