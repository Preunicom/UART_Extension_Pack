library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Receiver is
  Generic(
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
    clk, rst : in std_logic;
    serial_in : in std_logic;
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
    frame_error, parity_error : out std_logic;
    new_data : out std_logic
  );
end UART_Receiver;

architecture Behavioral of UART_Receiver is
  component Prescaler
    Generic(
      -- IN_FREQ_HZ has to be minimum 2*BAUD_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      clk_prescaled : out STD_LOGIC
    );
  end component;
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
  component Deserializer
    Generic(
      -- DATA_BITS + STOP_BITS <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, rst : in std_logic;
      serial_in : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error, parity_error : out std_logic;
      data_valid : out std_logic
    );
  end component;
  signal prescaled_clk_intern : std_logic;
  signal data_intern : std_logic_vector(DATA_BITS-1 downto 0);
  signal frame_error_intern, parity_error_intern : std_logic;
  signal data_ready_intern : std_logic;

  signal active_search_new : std_logic := '1';
  signal search_reset : std_logic := '0';
begin
  PRES: Prescaler generic map(IN_FREQ_HZ, BAUD_FREQ_HZ) port map(clk, search_reset or rst, prescaled_clk_intern);
  BRDESER: Buffer_Register_Deserializer generic map(DATA_BITS) port map(clk, rst, data_intern, frame_error_intern, parity_error_intern, data_ready_intern, parallel_out, frame_error, parity_error, new_data);
  DESER: Deserializer generic map(DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(prescaled_clk_intern, rst, serial_in, data_intern, frame_error_intern, parity_error_intern, data_ready_intern);

  -- Resets Prescaler when new UART package was detected to get data from mid of bits
  SEARCH: process(clk) 
  begin
    if rising_edge(clk) then
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
  end process;
  
end Behavioral;