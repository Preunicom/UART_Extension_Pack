library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Main_Unit is
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC
  );
end Main_Unit;

architecture Behavioral of Main_Unit is
  component UART_Unit
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
  component GPIO_Bank_Unit
    Generic (
        INPUTS : integer := 8;
        OUTPUTS : integer := 8
    );
    Port ( 
        clk, rst : in std_logic;
        write_en : in std_logic;
        config_in : in STD_LOGIC_VECTOR(OUTPUTS-1 downto 0);
        values_out : out STD_LOGIC_VECTOR(INPUTS-1 downto 0);
        gpio_data_in : in STD_LOGIC_VECTOR (INPUTS-1 downto 0);
        gpio_data_out : out STD_LOGIC_VECTOR (OUTPUTS-1 downto 0)
    );
  end component;
  component Decoder
    Generic (
      DATA_BITS : integer := 8;
      IN_FREQ_HZ : integer := 12000000
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      uart_inp : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_inp_valid : in std_logic;
      out_en : out std_logic;
      access_mode : out std_logic_vector(1 downto 0);
      unit_number : out std_logic_vector(2 downto 0); 
      unit_data : out std_logic_vector(DATA_BITS-1 downto 0)
    );
  end component;
  component Encoder
    Generic (
      DATA_BITS : integer := 8
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      write_en : in std_logic;
      uart_is_empty : in std_logic;
      unit_number : in std_logic_vector(2 downto 0); 
      unit_data : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_out : out std_logic_vector(DATA_BITS-1 downto 0);
      uart_out_valid : out std_logic
    );
  end component;
begin


  
end Behavioral;
