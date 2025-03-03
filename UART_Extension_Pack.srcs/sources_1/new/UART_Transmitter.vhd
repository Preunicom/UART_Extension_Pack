library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART_Transmitter is
  Generic (
    -- IN_FREQ_HZ has to be minimum 2*OUT_FREQ_HZ
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
    data_in : in std_logic_vector(DATA_BITS-1 downto 0);
    write_en : in std_logic;
    full : out std_logic;
    serial_out : out std_logic
  );
end UART_Transmitter;

architecture Behavioral of UART_Transmitter is
  component Prescaler
    Generic(
      -- IN_FREQ_HZ has to be minimum 2*OUT_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      clk_prescaled : out STD_LOGIC
    );
  end component;
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
  component Serializer
    Generic(
      -- DATA_BITS + STOP_BITS <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, rst, write_enable : in std_logic;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      serial_out : out std_logic;
      buffer_data_saved : out std_logic
    );
    end component;
  signal prescaled_clk_intern : std_logic;
  signal data_intern : std_logic_vector(DATA_BITS-1 downto 0);
  signal data_saved_intern : std_logic;
  signal full_intern : std_logic;
begin
  PRES: Prescaler generic map(IN_FREQ_HZ, BAUD_FREQ_HZ) port map(clk, rst, prescaled_clk_intern);
  BRSER: Buffer_Register_Serializer generic map(DATA_BITS) port map(clk, rst, write_en, data_in, data_saved_intern, data_intern, full_intern);
  SER: Serializer generic map(DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(prescaled_clk_intern, rst, full_intern, data_intern, serial_out, data_saved_intern);

  full <= full_intern;
  
end Behavioral;
