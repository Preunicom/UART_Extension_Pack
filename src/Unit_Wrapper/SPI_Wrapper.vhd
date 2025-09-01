--! @file
--! @brief SPI wrapper integrating SPI_Unit with host/scheduler interface.
--! @details Sets the active slave, sends data when the SPI unit is ready, and schedules received data back to the host. Reports invalid slave selects and send-while-busy errors.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! \defgroup UNIT_WRAPPER ExtPack unit wrapper.
--! @brief Wrapper for units of ExtPack.
--! @{

--! @brief Wraps an SPI_Unit to handle host commands and interface with the scheduler.
--! @details Following pins are needed:\n
--! - SCK pin\n
--! - CS pins (amount is set in the configuration)\n
--! - MISO pin\n
--! - MOSI pin
--! @details The access mode handles data sending and the current slave ID:
--! - "*0": Sends a message to the set slave.\n
--! - "*1": Sets slave to communicate with.
--! @details There are three situations where errors are forwarded to the Error_Unit:\n
--! - Too slow scheduling (error_to_host)\n
--! - Sending command while SPI_Unit not ready (error_from_host)\n
--! - Slave ID set command with invalid slave ID (error_from_host)
entity SPI_Wrapper is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host data bus in bits.
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz. @note Condition: >= 2x SPI_FREQ_HZ
    SPI_FREQ_HZ : integer := 9600; --! SPI SCK frequency in Hz.
    AMOUNT_SLAVES : integer := 1; --! Number of chip-select lines (slaves).
    SPI_MODE : integer := 0; --! SPI mode (0..3).
    LEAST_SIG_BIT_FIRST : integer := 0; --! Bit order: 0=MSB first, 1=LSB first.
    DATA_BITS : integer := 8 --! Number of bits per SPI transfer. @note Conditon: <= 14
  );
  Port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Host write strobe.
    access_mode : in std_logic_vector(1 downto 0); --! Access mode: bit0=1 selects slave, bit0=0 sends data.
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Payload from host (slave id or data byte(s)).
    unit_data_out : out std_logic_vector(13 downto 0); --! Data to host (received from SPI).
    scheduler_wanted : out std_logic; --! Request to scheduler for sending unit_data_out.
    scheduler_done : in std_logic; --! Scheduler acknowledge for completed send.
    error_to_host : out std_logic := '0'; --! Error: receive data overwrite while previous response pending.
    error_from_host : out std_logic := '0'; --! Error: invalid slave id or SPI busy on send.
    SCK : out std_logic; --! SPI clock output.
    CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1'); --! Chip-select lines (active low).
    MOSI : out std_logic; --! Master-Out-Slave-In.
    MISO : in std_logic --! Master-In-Slave-Out.
  );
end SPI_Wrapper;

--! Architecture connecting SPI_Unit to host commands and the scheduler, managing edge detection and errors.
architecture Behavioral of SPI_Wrapper is
  --! Component declaration for SPI_Unit: handles low-level SPI transfers.
  component SPI_Unit
    Generic (
      IN_FREQ_HZ : integer := 12000000;
      SPI_FREQ_HZ : integer := 9600;
      AMOUNT_SLAVES : integer := 1;
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0;
      LEAST_SIG_BIT_FIRST : integer := 0
    );
    Port (
      clk : in std_logic;
      rst : in std_logic;
      SCK : out std_logic;
      send_data : in std_logic_vector(DATA_BITS-1 downto 0);
      slave_id : in integer;
      write_en : in std_logic;
      ready : out std_logic;
      MOSI : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      received_data : out std_logic_vector(DATA_BITS-1 downto 0);
      new_data_received : out std_logic;
      MISO : in std_logic
    );
  end component;
  --! Previous write_en for edge detection.
  signal last_write_enable : std_logic := '0';
  --! Previous scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Indicates that a scheduler response is pending.
  signal scheduling_active : std_logic := '0';
  --! Indicates SPI_Unit is ready for a new transfer.
  signal spi_ready : std_logic := '1';
  --! Strobe to start an SPI transfer.
  signal spi_write_en : std_logic := '0';
  --! Pulse indicating new data was received from SPI_Unit.
  signal spi_new_data : std_logic := '0';
  --! Previous value of spi_new_data for edge detection.
  signal last_spi_new_data : std_logic := '0';
  --! Currently selected slave id.
  signal current_slave_id : integer := 0;
  --! Buffer for transmit data, zero-extended to 14 bits.
  signal unit_data_in_buffer : std_logic_vector(13 downto 0) := (others => '0');
  --! Buffer for received data, zero-extended to 14 bits.
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0');
begin
  --! The SPI Unit handling the communication via SPI.
  SPI: SPI_Unit generic map(IN_FREQ_HZ, SPI_FREQ_HZ, AMOUNT_SLAVES, DATA_BITS, SPI_MODE, LEAST_SIG_BIT_FIRST) port map(clk, rst, SCK, unit_data_in_buffer(DATA_BITS-1 downto 0), current_slave_id, spi_write_en, spi_ready, MOSI, CS, unit_data_out_buffer(DATA_BITS-1 downto 0), spi_new_data, MISO);

  --! Handles write_en edges: selects slave or sends data when SPI is ready. Reports errors otherwise.
  TRANSMIT: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        current_slave_id <= 0;
        error_from_host <= '0';
        unit_data_in_buffer(HOST_DATA_BITS-1 downto 0) <= (others => '0');
        spi_write_en <= '0';
      else      
        error_from_host <= '0';
        spi_write_en <= '0';
        if last_write_enable = '0' and write_en = '1' then
          -- Rising edge of write_en detected.
          -- Default to send unless access_mode indicates slave select.
          if access_mode(0) = '1' then
            -- Set current slave id.
            if to_integer(unsigned(unit_data_in)) < AMOUNT_SLAVES then
              -- Update current slave id.
              current_slave_id <= to_integer(unsigned(unit_data_in));
            else
              error_from_host <= '1';
            end if;
          elsif access_mode(0) = '0' then
            -- Send data.
            if spi_ready = '1' then
              -- Arm SPI transfer.
              unit_data_in_buffer(HOST_DATA_BITS-1 downto 0) <= unit_data_in;
              spi_write_en <= '1';
            else
              -- Error: SPI busy.
              error_from_host <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Schedules received SPI data to host; detects overwrite if previous response pending.
  RECEIVE: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        error_to_host <= '0';
        scheduling_active <= '0';
      else
        error_to_host <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- Scheduling finished: clear scheduler request and data.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        elsif last_spi_new_data = '0' and spi_new_data = '1' then
          -- Rising edge of spi_new_data: new SPI data available.
          if scheduling_active = '1' then
            -- Overwriting pending SPI data: raise error.
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out <= unit_data_out_buffer;
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;

  --! Captures previous values for edge detection (write_en, spi_new_data, scheduler_done).
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_enable <= '0';
        last_spi_new_data <= '0';
        last_scheduler_done <= '0';
      else
        last_write_enable <= write_en;
        last_scheduler_done <= scheduler_done;
        last_spi_new_data <= spi_new_data;
      end if;
    end if;
  end process;

end Behavioral;
