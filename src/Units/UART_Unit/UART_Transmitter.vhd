--! @file
--! @brief UART transmitter unit.
--! @details Handles buffering and serializing of TX data according to configured baud rate, data bits, stop bits, and parity settings.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--! Top-level UART transmitter entity, instantiating Prescaler, Buffer_Register_Serializer, and Serializer.
entity UART_Transmitter is
  Generic (
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz.
    BAUD_FREQ_HZ : integer := 9600;   --! UART baud rate in Hz.
    DATA_BITS : integer := 8;         --! Number of data bits per frame. @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    STOP_BITS : integer := 1;         --! Number of stop bits. @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_ACTIVE : integer := 0;     --! 0: No parity; 1: Parity enabled (even/odd per PARITY_MODE). @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_MODE : integer := 0        --! 0: Even parity; 1: Odd parity.
  );
  Port ( 
    clk : in std_logic;         --! Clock signal.
    rst : in std_logic;         --! Reset signal.
    data_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel TX data input.
    write_en : in std_logic;    --! Strobe to write data into TX buffer.
    full : out std_logic;       --! TX buffer full / transmitter not ready.
    serial_out : out std_logic  --! Serialized TX output bitstream.
  );
end UART_Transmitter;

--! Architecture connecting prescaler, buffering, and serialization for UART transmission.
architecture Behavioral of UART_Transmitter is
  --! Component declaration for prescaler generating baud rate clock enable.
  component Prescaler
    Generic(
      IN_FREQ_HZ : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      clk_en_prescaled : out STD_LOGIC
    );
  end component;
  --! Component declaration for buffer and register feeding the serializer.
  component Buffer_Register_Serializer
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
  --! Component declaration for serializer converting parallel data to serial format.
  component Serializer
    Generic(
      -- DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0    -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, clk_en_prescaled, rst, write_enable : in std_logic;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      serial_out : out std_logic;
      buffer_data_saved : out std_logic
    );
    end component;
  --! Prescaled clock enable signal for serializer.
  signal prescaled_clk_en_intern : std_logic;
  --! Internal data bus between buffer/register and serializer.
  signal data_intern : std_logic_vector(DATA_BITS-1 downto 0);
  --! Indicates serializer has stored the buffered data.
  signal data_saved_intern : std_logic;
  --! Internal full flag from buffer/register.
  signal full_intern : std_logic;
begin
  --! Instantiate prescaler.
  PRES: Prescaler generic map(IN_FREQ_HZ, BAUD_FREQ_HZ) port map(clk, rst, prescaled_clk_en_intern);
  --! Instantiate buffer/register feeding serializer.
  BRSER: Buffer_Register_Serializer generic map(DATA_BITS) port map(clk, rst, write_en, data_in, data_saved_intern, data_intern, full_intern);
  --! Instantiate serializer.
  SER: Serializer generic map(DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, prescaled_clk_en_intern, rst, full_intern, data_intern, serial_out, data_saved_intern);

  full <= full_intern;
  
end Behavioral;
