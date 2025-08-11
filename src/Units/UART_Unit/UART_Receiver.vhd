--! @file
--! @brief UART receiver unit.
--! @details Handles detection, deserialization, buffering, and error reporting for UART RX data with configurable baud rate, data bits, stop bits, and parity.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Top-level UART receiver entity, instantiating Prescaler, Buffer_Register_Deserializer, and Deserializer.
entity UART_Receiver is
  Generic(
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz.
    BAUD_FREQ_HZ : integer := 9600; --! UART baud rate in Hz.
    DATA_BITS : integer := 8; --! Number of data bits per frame. @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    STOP_BITS : integer := 1; --! Number of stop bits. @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_ACTIVE : integer := 0; --! 0: No parity; 1: Parity enabled (even/odd per PARITY_MODE). @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_MODE : integer := 0 --! 0: Even parity; 1: Odd parity.
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    serial_in : in std_logic; --! Serialized RX input bitstream.
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0); --! Parallel RX data output.
    frame_error : out std_logic; --! RX framing error.
    parity_error : out std_logic; --! RX parity error.
    new_data : out std_logic --! Pulse: new RX data available.
  );
end UART_Receiver;

--! Architecture connecting prescaler, deserializer, and buffering for UART reception with start-bit search and mid-bit sampling.
architecture Behavioral of UART_Receiver is
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
  --! Component declaration for buffer/register storing received UART data and associated error flags.
  component Buffer_Register_Deserializer
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      frame_error_in, parity_error_in : in std_logic;
      write_en : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error_out, parity_error_out : out std_logic;
      new_data : out std_logic
    );
  end component;
  --! Component declaration for deserializer converting serial RX data to parallel format.
  component Deserializer
    Generic(
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0;
      PARITY_MODE : integer := 0
    );
    Port ( 
      clk, clk_en_prescaled, rst : in std_logic;
      serial_in : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error, parity_error : out std_logic;
      data_valid : out std_logic
    );
  end component;
  --! Prescaled clock enable signal for deserializer.
  signal prescaled_clk_en_intern : std_logic;
  --! Parallel data output from deserializer.
  signal data_intern : std_logic_vector(DATA_BITS-1 downto 0);
  --! RX framing error from deserializer.
  signal frame_error_intern : std_logic;
  --! RX parity error from deserializer.
  signal parity_error_intern : std_logic;
  --! Pulse indicating new parallel data from deserializer.
  signal data_ready_intern : std_logic;
  --! Indicates that start-bit search is currently active.
  signal active_search_new : std_logic := '1';
  --! Internal reset for prescaler during start-bit search.
  signal search_reset : std_logic := '1';
  --! Combined reset signal (global reset or search reset).
  signal rst_combined : std_logic := '0';
begin
  --! Instantiate prescaler.
  PRES: Prescaler generic map(IN_FREQ_HZ, BAUD_FREQ_HZ) port map(clk, rst_combined, prescaled_clk_en_intern);
  --! Instantiate buffer/register for received UART data.
  BRDESER: Buffer_Register_Deserializer generic map(DATA_BITS) port map(clk, rst, data_intern, frame_error_intern, parity_error_intern, data_ready_intern, parallel_out, frame_error, parity_error, new_data);
  --! Instantiate deserializer.
  DESER: Deserializer generic map(DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, prescaled_clk_en_intern, rst_combined, serial_in, data_intern, frame_error_intern, parity_error_intern, data_ready_intern);

  --! Monitors RX line to detect start bit, controls search_reset to align sampling to mid-bit.
  --! Reset prescaler upon detection of new UART frame to sample near mid-bit.
  SEARCH: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Idle when reseted
        search_reset <= '1';
        active_search_new <= '1';
      else
        search_reset <= '0';
        if data_ready_intern = '1' then
          -- last bit of package read
          --> Search for new package started
          active_search_new <= '1';
        end if;
        if active_search_new = '1' then
          -- Reseting as long as UART idle
          search_reset <= '1';
          -- End search and reset if falling edge on RX pin is detected  (start bit)
          -- (pin is always 1 if idle, so 0 has to be the first bit --> No further edge testing needed)
          if serial_in = '0' then
            search_reset <= '0';
            active_search_new <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  rst_combined <= rst or search_reset;
  
end Behavioral;