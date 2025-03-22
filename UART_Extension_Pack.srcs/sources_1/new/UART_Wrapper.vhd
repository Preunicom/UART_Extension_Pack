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
  signal uart_received_valid_last : std_logic;
  signal frame_error, parity_error : std_logic;
  signal last_scheduler_done : std_logic := '0';

  -- Not more than 14 data bits possible with UART_Unit
  signal unit_data_in_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller UART data vector with zeros
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller UART data vector with zeros
begin
  UART: UART_Unit generic map(IN_FREQ_HZ, BAUD_FREQ_HZ, DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, rst, unit_data_in_buffer(DATA_BITS-1 downto 0), write_en_int, full_int, TX_pin, unit_data_out_buffer(DATA_BITS-1 downto 0), frame_error, parity_error, uart_received_valid, RX_pin);

  TRANSMIT: process(clk, rst)
  begin
    if rst = '1' then
      unit_data_in_buffer <= (others => '0');
      write_en_int <= '0';
    elsif rising_edge(clk) then
      if write_en = '1' and write_en_last = '0' then
        -- new data for UART_Unit
        write_en_int <= '1';
        -- Sync unit_data_in_buffer to match write_en_int
        unit_data_in_buffer(HOST_DATA_BITS-1 downto 0)  <= unit_data_in;
      end if;
      if (full_int = '1' and full_int_last = '0') or write_en = '0' then
        -- current data read from UART_Unit or current data is invalid
        write_en_int <= '0';
      end if;
    end if;
  end process;
  
  RECEIVE: process(uart_received_valid, uart_received_valid_last, frame_error, parity_error, scheduler_done, rst)
  begin
    if rst = '1' or (last_scheduler_done = '0' and scheduler_done = '1') then
      -- Ignoring uart_received_valid in if because there are only valid values from UART Deserializer Buffer if there was once one.
      -- reset scheduler_wanted
      scheduler_wanted <= '0';
    elsif uart_received_valid = '1' and uart_received_valid_last = '0' and frame_error = '0' and parity_error = '0' then  
      -- Must be a edge in if because Deserializer is prescaled and so write_en in buffer (and so uart_received_valid) is longer active than 1 clock cyle.  
      -- new package received with no errors
      scheduler_wanted <= '1';
    end if;
  end process;

  unit_data_out <= unit_data_out_buffer;

  EDGE_DETECTION: process(clk, rst)
  begin
    if rst = '1' then
      last_scheduler_done <= '0';
      uart_received_valid_last <= '0';
      write_en_last <= '0';
      full_int_last <= '0';
    elsif rising_edge(clk) then
      uart_received_valid_last <= uart_received_valid;
      last_scheduler_done <= scheduler_done;
      write_en_last <= write_en;
      full_int_last <= full_int;
    end if;
  end process;

end Behavioral;
