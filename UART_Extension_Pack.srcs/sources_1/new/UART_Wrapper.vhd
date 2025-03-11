library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART_Wrapper is
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
    new_data_received : out std_logic;
    RX_pin : in std_logic;
    reset_new_data_received : in std_logic
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
  signal uart_received_valid : std_logic;
  signal uart_received_valid_last : std_logic;
  signal frame_error, parity_error : std_logic;
begin
  UART: UART_Unit generic map(IN_FREQ_HZ, BAUD_FREQ_HZ, DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, rst, send_data, write_en_int, full_int, TX_pin, received_data, frame_error, parity_error, uart_received_valid, RX_pin);

  TRANSMIT: process(write_en, write_en_last, full_int, rst)
  begin
    if rst = '1' then
      write_en_int <= '0';
    else 
      if write_en = '1' and write_en_last = '0' then
        -- new write_en for UART_Unit
        write_en_int <= '1';
      end if;
      if full_int = '1' and write_en = '1' and write_en_last = '1' then
        -- current write_en read from UART_Unit
        write_en_int <= '0';
      end if;
    end if;
  end process;
  
  EDGE_DETECTION_TRANSMIT: process(clk, rst)
  begin
    if rst = '1' then
      write_en_last <= '0';
    elsif rising_edge(clk) then
      -- set write_en_last to current write_en
      write_en_last <= write_en;
    end if;
  end process;

  full <= full_int;
  
  RECEIVE: process(uart_received_valid, reset_new_data_received)
  begin
    if uart_received_valid = '1' and uart_received_valid_last = '0' and frame_error = '0' and parity_error = '0' then    
      -- new package received with no errors
      new_data_received <= '1';
    elsif reset_new_data_received = '1' or rst = '1' then
      -- reset new_data_received
      new_data_received <= '0';
    end if;
  end process;

  EDGE_DETECTION_RECEIVE: process(clk, rst)
  begin
    if rst = '1' then
      uart_received_valid_last <= '0';
    elsif rising_edge(clk) then
      -- set uart_received_valid_last to current uart_received_valid
      uart_received_valid_last <= uart_received_valid;
    end if;
  end process;

end Behavioral;
