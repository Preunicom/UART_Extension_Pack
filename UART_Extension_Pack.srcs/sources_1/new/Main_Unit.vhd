library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Main_Unit is
  Generic(
    -- FPGA_FREQ has to be minimum 2*HOST_BAUD
    FPGA_FREQ : integer := 12000000;
    HOST_BAUD : integer := 1000000;
    -- HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15 has to be fullfilled
    -- HOST_DATA_BITS >= 8 has to be fullfilled
    HOST_DATA_BITS : integer := 8;
    HOST_STOP_BITS : integer := 1;
    HOST_PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
    HOST_PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
  );
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    tx_pin_host : out std_logic;
    rx_pin_host : in std_logic;
    ----------------- UNIT PORTS -----------------
    tx_pin_a : out std_logic;
    rx_pin_a : in std_logic;
    gpio_pins_in : in STD_LOGIC_VECTOR (0 downto 0);
    gpio_pins_out : out STD_LOGIC_VECTOR (1 downto 0)
    
    --------------- UNIT PORTS END ---------------
  );
end Main_Unit;

architecture Behavioral of Main_Unit is
  component UART_Unit
    Generic (
      -- IN_FREQ_HZ has to be minimum 2*OUT_FREQ_HZ
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
  component UART_Wrapper
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
      unit_data_out : out std_logic_vector(HOST_DATA_BITS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      TX_pin : out std_logic;
      RX_pin : in std_logic
    );
  end component;
  component GPIO_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN/OUT_PINS <= HOST_DATA_BITS has to be fullfilled
      -- IN/OUT_PINS >= 1 has to be fullfilled
      IN_PINS : integer := 8;
      OUT_PINS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
      unit_data_in : in STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      gpio_data_in : in STD_LOGIC_VECTOR (IN_PINS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (OUT_PINS-1 downto 0)
    );
  end component;
  component Timer_Wrapper
    generic (
      HOST_DATA_BITS : integer := 8;
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000
    );
    port (
      clk, rst         : in  STD_LOGIC;
      write_en         : in  std_logic;
      access_mode      : in  std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
      unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      unit_data_out    : out STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done   : in  std_logic
    );
  end component;
  component Decoder
    Generic (
      DATA_BITS : integer := 8;
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      uart_inp : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_inp_valid : in std_logic;
      uart_error : in std_logic;
      out_en : out std_logic;
      access_mode : out std_logic_vector(1 downto 0);
      unit_number : out std_logic_vector(5 downto 0); 
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
      unit_number : in std_logic_vector(5 downto 0);
      unit_data : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_out : out std_logic_vector(DATA_BITS-1 downto 0);
      uart_out_valid : out std_logic;
      schedule_next : out std_logic
    );
  end component;
  component PriorityScheduler
    Port ( 
      clk, rst : in STD_LOGIC;
      schedule_next : in std_logic;
      outp_valid : out std_logic;
      control_sig : out std_logic_vector(5 downto 0);
      scheduler_wanted : in std_logic_vector(63 downto 0);
      scheduler_done : out std_logic_vector(63 downto 0)
    );
  end component;
  component MUX
    generic (
      WIDTH : integer := 8
    );
    port (
      control : in  STD_LOGIC_VECTOR(5 downto 0);
      inp_U00 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U01 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U02 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U03 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U04 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U05 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U06 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U07 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U08 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U09 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U10 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U11 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U12 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U13 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U14 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U15 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U16 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U17 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U18 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U19 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U20 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U21 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U22 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U23 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U24 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U25 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U26 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U27 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U28 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U29 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U30 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U31 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U32 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U33 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U34 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U35 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U36 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U37 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U38 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U39 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U40 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U41 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U42 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U43 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U44 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U45 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U46 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U47 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U48 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U49 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U50 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U51 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U52 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U53 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U54 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U55 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U56 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U57 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U58 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U59 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U60 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U61 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U62 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      inp_U63 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      outp    : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0)
    );
  end component;
  component DEMUX
    Port ( 
      control : in STD_LOGIC_VECTOR (5 downto 0);
      inp : in STD_LOGIC;
      outp : out STD_LOGIC_VECTOR(63 downto 0)
    );
  end component;
  
  -- host send
  signal host_send_data : std_logic_vector(HOST_DATA_BITS-1 downto 0);
  signal host_write_en : std_logic;
  signal host_full : std_logic;
  -- host receive
  signal host_received_data : std_logic_vector(HOST_DATA_BITS-1 downto 0);
  signal host_new_data_received : std_logic;
  signal host_frame_error, host_parity_error : std_logic;
  signal host_any_uart_error : std_logic;
  signal host_empty : std_logic;

  -- decoder
  signal decode_out_en : std_logic;
  signal decoded_access_mode : std_logic_vector(1 downto 0);
  signal decoded_unit_number : std_logic_vector(5 downto 0);
  signal decoded_unit_data : std_logic_vector(HOST_DATA_BITS-1 downto 0);

  -- demux
  signal unit_en : std_logic_vector(63 downto 0);

  -- Units
  signal unit_scheduler_wanted : std_logic_vector(63 downto 0) := (others => '0');
  signal unit_scheduler_done : std_logic_vector(63 downto 0) := (others => '0');
  
  signal unit_data_out_U00 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U01 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U02 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U03 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U04 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U05 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U06 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U07 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U08 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U09 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U10 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U11 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U12 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U13 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U14 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U15 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U16 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U17 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U18 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U19 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U20 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U21 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U22 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U23 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U24 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U25 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U26 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U27 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U28 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U29 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U30 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U31 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U32 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U33 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U34 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U35 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U36 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U37 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U38 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U39 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U40 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U41 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U42 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U43 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U44 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U45 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U46 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U47 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U48 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U49 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U50 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U51 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U52 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U53 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U54 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U55 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U56 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U57 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U58 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U59 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U60 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U61 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U62 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');
  signal unit_data_out_U63 : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '0');

  -- scheduler
  signal schedule_control_sig : std_logic_vector(5 downto 0);
  signal scheduler_write_en : std_logic := '0';
  signal scheduler_schedule_next: std_logic;

  -- mux
  signal mux_unit_data_out : std_logic_vector(HOST_DATA_BITS-1 downto 0);
  
begin
  UART_HOST: UART_Unit generic map(FPGA_FREQ, HOST_BAUD, HOST_DATA_BITS, HOST_STOP_BITS, HOST_PARITY_ACTIVE, HOST_PARITY_MODE) port map(clk, rst, host_send_data, host_write_en, host_full, tx_pin_host, host_received_data, host_frame_error, host_parity_error, host_new_data_received, rx_pin_host);
  DECODE: Decoder generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst, host_received_data, host_new_data_received, host_any_uart_error, decode_out_en, decoded_access_mode, decoded_unit_number, decoded_unit_data);
  EN_DEMUX: DEMUX port map(decoded_unit_number, decode_out_en, unit_en);

  ----------------- UNITS -----------------
  U00_UART: UART_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 250000, 8, 1, 0, 0) port map(clk, rst, unit_en(0), decoded_access_mode, decoded_unit_data, unit_data_out_U00, unit_scheduler_wanted(0), unit_scheduler_done(0), tx_pin_a, rx_pin_a);
  U01_GPIO: GPIO_Wrapper generic map(HOST_DATA_BITS, 1, 2) port map(clk, rst, unit_en(1), decoded_access_mode, decoded_unit_data, unit_data_out_U01, unit_scheduler_wanted(1), unit_scheduler_done(1), gpio_pins_in, gpio_pins_out);
  U02_TIME: Timer_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst, unit_en(2), decoded_access_mode, decoded_unit_data, unit_data_out_U02, unit_scheduler_wanted(2), unit_scheduler_done(2));

  --------------- UNITS END ---------------
  
  SCHEDULE: PriorityScheduler port map(clk, rst, scheduler_schedule_next, scheduler_write_en, schedule_control_sig, unit_scheduler_wanted, unit_scheduler_done);
  SCHED_MUX: MUX generic map(HOST_DATA_BITS) port map(schedule_control_sig, 
    unit_data_out_U00, unit_data_out_U01, unit_data_out_U02, unit_data_out_U03, unit_data_out_U04, unit_data_out_U05, unit_data_out_U06, unit_data_out_U07, unit_data_out_U08, unit_data_out_U09, 
    unit_data_out_U10, unit_data_out_U11, unit_data_out_U12, unit_data_out_U13, unit_data_out_U14, unit_data_out_U15, unit_data_out_U16, unit_data_out_U17, unit_data_out_U18, unit_data_out_U19,
    unit_data_out_U20, unit_data_out_U21, unit_data_out_U22, unit_data_out_U23, unit_data_out_U24, unit_data_out_U25, unit_data_out_U26, unit_data_out_U27, unit_data_out_U28, unit_data_out_U29, 
    unit_data_out_U30, unit_data_out_U31, unit_data_out_U32, unit_data_out_U33, unit_data_out_U34, unit_data_out_U35, unit_data_out_U36, unit_data_out_U37, unit_data_out_U38, unit_data_out_U39, 
    unit_data_out_U40, unit_data_out_U41, unit_data_out_U42, unit_data_out_U43, unit_data_out_U44, unit_data_out_U45, unit_data_out_U46, unit_data_out_U47, unit_data_out_U48, unit_data_out_U49, 
    unit_data_out_U50, unit_data_out_U51, unit_data_out_U52, unit_data_out_U53, unit_data_out_U54, unit_data_out_U55, unit_data_out_U56, unit_data_out_U57, unit_data_out_U58, unit_data_out_U59, 
    unit_data_out_U60, unit_data_out_U61, unit_data_out_U62, unit_data_out_U63, mux_unit_data_out);
  ENCODE: Encoder generic map(HOST_DATA_BITS) port map(clk, rst, scheduler_write_en, host_empty, schedule_control_sig, mux_unit_data_out, host_send_data, host_write_en, scheduler_schedule_next);

  host_any_uart_error <= host_frame_error or host_parity_error;
  host_empty <= not host_full;

end Behavioral;
