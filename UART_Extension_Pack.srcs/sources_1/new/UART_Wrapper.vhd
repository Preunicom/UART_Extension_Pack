--! @file
--! @brief UART wrapper integrating UART_Unit with host/scheduler interface.
--! @details Sends host data when the UART unit is ready and schedules received UART data back to the host. Reports send-while-busy and RX-frame/parity errors, and detects overwrite of pending responses.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! \defgroup UNIT_WRAPPER ExtPack unit wrapper.
--! @brief Wrapper for units of ExtPack.
--! @{

--! @brief Wraps a UART_Unit to handle host commands and interface with the scheduler.
--! @details Can be configured with BAUD rate, data bits, stop bits and parity bit.  
--! Needs two pins (rx and tx) of the FPGA.
--! @details Normally:\n
--!  - data bits: 5-9\n
--!  - stop bits: 1-2\n
--!  - parity bit: 0-1
--! @details UART messages are directly forwarded from unit to the host or from the host to the unit.  
--! The access mode is ignored.
--! @note
--! - Integer dividable baud rates lead to more stable UART communication\n
--! - Data bits have to be more than 5 and all bits (stop, data and parity) have to be less or equal 15.\n
--! - If there is too much traffic on the ExtPack and UART Unit has to less priority and is receiving too much load it is possible that UART packages are getting lost because it is scheduled too slow or never because of starvation.\n
--! - The system operates on a Best-Effort Delivery basis, meaning it strives to transmit data as efficiently as possible but does not guarantee delivery.
entity UART_Wrapper is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host data bus in bits.
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz. @note Condition: >= 2x BAUD_FREQ_HZ.
    BAUD_FREQ_HZ : integer := 9600; --! UART baud rate in Hz.
    DATA_BITS : integer := 8; --! Bits per frame (without parity/stop). @note Condition: >= 5 and DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15.
    STOP_BITS : integer := 1; --! Number of stop bits (1 or 2). @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15.
    PARITY_ACTIVE : integer := 0; --! 0: No parity; 1: Parity enabled (even/odd by PARITY_MODE). @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15.
    PARITY_MODE : integer := 0 --! 0: Even parity; 1: Odd parity.
  );
  Port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Host write strobe.
    access_mode : in std_logic_vector(1 downto 0); --! Unused.
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Payload from host (data to transmit).
    unit_data_out : out std_logic_vector(13 downto 0); --! Data to host (received UART byte, zero-extended).
    scheduler_wanted : out std_logic; --! Request to scheduler for sending unit_data_out.
    scheduler_done : in std_logic; --! Scheduler acknowledge for completed send.
    error_to_host : out std_logic := '0'; --! Error: RX error or overwrite of pending response.
    error_from_host : out std_logic := '0'; --! Error: TX data lost because UART was busy.
    TX_pin : out std_logic; --! UART transmitter pin.
    RX_pin : in std_logic --! UART receiver pin.
  );
end UART_Wrapper;

--! Architecture connecting UART_Unit to host commands and the scheduler, with edge detection and error handling.
architecture Behavioral of UART_Wrapper is
  --! Component declaration for UART_Unit: handles low-level UART TX/RX.
  component UART_Unit 
    Generic (
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8; 
      STOP_BITS : integer := 1; 
      PARITY_ACTIVE : integer := 0; 
      PARITY_MODE : integer := 0
    );
    Port (
      clk : in STD_LOGIC; 
      rst : in STD_LOGIC; 
      send_data : in std_logic_vector(DATA_BITS-1 downto 0);
      write_en : in std_logic; 
      full : out std_logic; 
      TX_pin : out std_logic;
      received_data : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error : out std_logic;
      parity_error : out std_logic;
      new_data_received : out std_logic; 
      RX_pin : in std_logic
    );
  end component;
  --! Internal write strobe forwarded to UART_Unit.
  signal write_en_int : std_logic := '0';
  --! Previous value of write_en for edge detection.
  signal write_en_last : std_logic := '0';
  --! UART_Unit TX full indicator (not ready).
  signal full_int : std_logic;
  --! Previous value of full_int for edge detection.
  signal full_int_last : std_logic;
  --! Pulse from UART_Unit indicating a new RX byte is available.
  signal uart_received_valid : std_logic;
  --! Previous value of uart_received_valid for edge detection.
  signal last_uart_received_valid : std_logic;
  --! RX error flags from UART_Unit.
  signal frame_error, parity_error : std_logic;
  --! Previous value of scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Indicates a pending scheduler response until scheduler_done.
  signal scheduling_active : std_logic := '0';
  --! Remembers that an enqueued TX payload became invalid before being accepted.
  signal last_write_en_invalid : std_logic := '0';
  --! Tracks whether a TX payload is currently queued for UART_Unit.
  signal data_in_queue_to_send : std_logic := '0';
  --! TX buffer (host width zero-extended to 14 bits).
  signal unit_data_in_buffer : std_logic_vector(13 downto 0) := (others => '0');
  --! RX buffer (zero-extended to 14 bits) forwarded to host.
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0');
begin
  --! UART Unit handling the UART communication.
  UART: UART_Unit generic map(IN_FREQ_HZ, BAUD_FREQ_HZ, DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, rst, unit_data_in_buffer(DATA_BITS-1 downto 0), write_en_int, full_int, TX_pin, unit_data_out_buffer(DATA_BITS-1 downto 0), frame_error, parity_error, uart_received_valid, RX_pin);

  --! Handles write_en edges and feeds TX data to UART_Unit; detects TX-loss errors.
  TRANSMIT: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        unit_data_in_buffer <= (others => '0');
        write_en_int <= '0';
        last_write_en_invalid <= '0';
        error_from_host <= '0';
        data_in_queue_to_send <= '0';
      else
        last_write_en_invalid <= '0';
        error_from_host <= '0';
        if write_en = '1' and write_en_last = '0' then
          -- Rising edge of write_en: new TX data from host.
          write_en_int <= '1';
          -- Latch TX payload to align with write_en_int.
          unit_data_in_buffer(HOST_DATA_BITS-1 downto 0)  <= unit_data_in;
          data_in_queue_to_send <= '1';
        end if;
        if (full_int_last = '0' and full_int = '1') or write_en = '0' then
          -- TX accepted by UART_Unit or current data became invalid.
          write_en_int <= '0';
          data_in_queue_to_send <= '0';
          if data_in_queue_to_send = '1' and not(full_int_last = '0' and full_int = '1') then
            -- Queued TX became invalid and wasn't processed this cycle.
            last_write_en_invalid <= '1';
          end if;
          if last_write_en_invalid = '1' and not(full_int_last = '0' and full_int = '1') then
            -- TX data lost across cycles: raise error.
            error_from_host <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Schedules received UART data to host; flags RX errors and overwrite of pending responses.
  RECEIVE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then 
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        scheduling_active <= '0';
        error_to_host <= '0';
      else
        error_to_host <= '0';
        if last_scheduler_done = '0' and scheduler_done = '1' then
          -- Scheduling finished: clear scheduler request and data.
          -- Ignore uart_received_valid here: buffered values are only valid after first RX.
          -- Clear scheduler_wanted.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        elsif last_uart_received_valid = '0' and uart_received_valid = '1' then  
          if frame_error = '0' and parity_error = '0' then
            -- Schedule current RX byte.
            if scheduling_active = '1' then
              -- Overwriting pending RX data: raise error.
              error_to_host <= '1';
            end if;
            scheduler_wanted <= '1';
            unit_data_out <= unit_data_out_buffer;
            scheduling_active <= '1';
          else
            -- RX framing/parity error.
            error_to_host <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Captures previous values for edge detection (write_en, full_int, uart_received_valid, scheduler_done).
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_scheduler_done <= '0';
        last_uart_received_valid <= '0';
        write_en_last <= '0';
        full_int_last <= '0';
      else
        last_uart_received_valid <= uart_received_valid;
        last_scheduler_done <= scheduler_done;
        write_en_last <= write_en;
        full_int_last <= full_int;
      end if;
    end if;
  end process;

end Behavioral;
