library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_Wrapper is
  Generic (
    HOST_DATA_BITS : integer := 8;
    -- IN_FREQ_HZ has to be minimum 2*BAUD_FREQ_HZ
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
    access_mode : in std_logic_vector(1 downto 0); -- unused
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
    unit_data_out : out std_logic_vector(13 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic;
    error_to_host : out std_logic := '0';
    error_from_host : out std_logic := '0';
    TX_pin : out std_logic;
    RX_pin : in std_logic
  );
end UART_Wrapper;

architecture Behavioral of UART_Wrapper is
  component UART_Unit 
    Generic (
      -- IN_FREQ_HZ has to be minimum 2*BAUD_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      -- DATA_BITS + STOP_BITS <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      send_data : in std_logic_vector(DATA_BITS-1 downto 0);
      write_en : in std_logic;
      full : out std_logic;
      TX_pin : out std_logic;

      received_data : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error, parity_error : out std_logic;
      new_data_received : out std_logic;
      RX_pin : in std_logic
    );
  end component;
  signal write_en_int : std_logic := '0';
  signal write_en_last : std_logic := '0';
  signal full_int : std_logic;
  signal full_int_last : std_logic;
  signal uart_received_valid : std_logic;
  signal last_uart_received_valid : std_logic;
  signal frame_error, parity_error : std_logic;
  signal last_scheduler_done : std_logic := '0';
  signal scheduling_active : std_logic := '0';
  signal last_write_en_invalid : std_logic := '0';
  signal data_in_queue_to_send : std_logic := '0';

  -- Not more than 14 data bits possible with UART_Unit
  signal unit_data_in_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller UART data vector with zeros
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller UART data vector with zeros
begin
  UART: UART_Unit generic map(IN_FREQ_HZ, BAUD_FREQ_HZ, DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, rst, unit_data_in_buffer(DATA_BITS-1 downto 0), write_en_int, full_int, TX_pin, unit_data_out_buffer(DATA_BITS-1 downto 0), frame_error, parity_error, uart_received_valid, RX_pin);

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
          -- new data for UART_Unit
          write_en_int <= '1';
          -- Sync unit_data_in_buffer to match write_en_int
          unit_data_in_buffer(HOST_DATA_BITS-1 downto 0)  <= unit_data_in;
          data_in_queue_to_send <= '1';
        end if;
        if (full_int_last = '0' and full_int = '1') or write_en = '0' then
          -- current data read from UART_Unit or current data is invalid
          write_en_int <= '0';
          data_in_queue_to_send <= '0';
          if data_in_queue_to_send = '1' and not(full_int_last = '0' and full_int = '1') then
            -- Waiting data got invalid and not processed in this clock cycle
            last_write_en_invalid <= '1';
          end if;
          if last_write_en_invalid = '1' and not(full_int_last = '0' and full_int = '1') then
          --  Data got invalid and not processed in this and last clock cycle --> Data got lost --> error
          error_from_host <= '1';
        end if;
        end if;
      end if;
    end if;
  end process;

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
          -- scheduling finished --> resets request at scheduler
          -- Ignoring uart_received_valid in if because there are only valid values from UART Deserializer Buffer if there was once one.
          -- reset scheduler_wanted
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        elsif last_uart_received_valid = '0' and uart_received_valid = '1' then  
          if frame_error = '0' and parity_error = '0' then
            -- Schedule current UART package
            if scheduling_active = '1' then
              -- Overwriting last received UART package -> Error
              error_to_host <= '1';
            end if;
            scheduler_wanted <= '1';
            unit_data_out <= unit_data_out_buffer;
            scheduling_active <= '1';
          else
            -- UART error
            error_to_host <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

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
