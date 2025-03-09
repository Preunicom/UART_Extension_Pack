library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Main_Unit is
  Generic(
    HOST_BAUD : integer := 1000000;
    FPGA_FREQ : integer := 12000000
  );
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    tx_pin_host, tx_pin_a : out std_logic;
    rx_pin_host, rx_pin_a : in std_logic;
    gpio_pins_in : in STD_LOGIC_VECTOR (7 downto 0);
    gpio_pins_out : out STD_LOGIC_VECTOR (7 downto 0)
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
  component UART_Wrapper
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
      RX_pin : in std_logic;
      reset_new_data_received : std_logic
    );
  end component;
  component GPIO_Wrapper
    Generic (
      IO_PINS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      enable : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
      config_in : in STD_LOGIC_VECTOR(IO_PINS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      values_out : out STD_LOGIC_VECTOR(IO_PINS-1 downto 0);
      gpio_data_in : in STD_LOGIC_VECTOR (IO_PINS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (IO_PINS-1 downto 0)
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
      uart_out_valid : out std_logic;
      schedule_next : out std_logic
    );
  end component;
  component PriorityScheduler
    Port ( 
      clk, rst : in STD_LOGIC;
      inp_ressource_ready : in std_logic; --en
      outp_valid : out std_logic;
      control_sig : out std_logic_vector(2 downto 0);
      inp_a : in STD_LOGIC;
      inp_b : in STD_LOGIC;
      inp_c : in STD_LOGIC;
      inp_d : in STD_LOGIC;
      inp_e : in STD_LOGIC;
      inp_f : in STD_LOGIC;
      inp_g : in STD_LOGIC;
      inp_h : in STD_LOGIC;
      outp_a : out STD_LOGIC;
      outp_b : out STD_LOGIC;
      outp_c : out STD_LOGIC;
      outp_d : out STD_LOGIC;
      outp_e : out STD_LOGIC;
      outp_f : out STD_LOGIC;
      outp_g : out STD_LOGIC;
      outp_h : out STD_LOGIC
    );
  end component;
  component MUX
    generic (
      WIDTH : integer := 8
    );
    Port ( 
      control : in STD_LOGIC_VECTOR (2 downto 0);
      inp_a : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_b : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_c : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_d : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_e : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_f : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_g : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      inp_h : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
      outp : out STD_LOGIC_VECTOR (WIDTH-1 downto 0)
    );
  end component;
  component DEMUX
    Port ( 
      control : in STD_LOGIC_VECTOR (2 downto 0);
      inp : in STD_LOGIC;
      outp_a : out STD_LOGIC;
      outp_b : out STD_LOGIC;
      outp_c : out STD_LOGIC;
      outp_d : out STD_LOGIC;
      outp_e : out STD_LOGIC;
      outp_f : out STD_LOGIC;
      outp_g : out STD_LOGIC;
      outp_h : out STD_LOGIC
    );
  end component;

  -- host send
  signal host_send_data : std_logic_vector(7 downto 0);
  signal host_write_en : std_logic;
  signal host_full : std_logic;
  -- host receive
  signal host_received_data : std_logic_vector(7 downto 0);
  signal host_new_data_received : std_logic;

  -- decoder
  signal decode_out_en : std_logic;
  signal decode_access_mode : std_logic_vector(1 downto 0);
  signal decode_unit_number : std_logic_vector(2 downto 0);
  signal decode_unit_data : std_logic_vector(7 downto 0);

  -- demux
  signal a_en : std_logic; -- UART
  signal b_en : std_logic; -- GPIO

  -- a (UART)
  signal a_received_data : std_logic_vector(7 downto 0);
  signal a_new_data_received : std_logic;
  signal a_scheduler_done : std_logic;
    
  -- b (GPIO)
  signal b_scheduler_wanted : std_logic;
  signal b_scheduler_done : std_logic;
  signal b_values_out : std_logic_vector(7 downto 0);

  -- scheduler
  signal schedule_control_sig : std_logic_vector(2 downto 0);
  signal scheduler_write_en : std_logic;
  signal scheduler_schdule_next: std_logic;

  -- mux
  signal mux_unit_data_out : std_logic_vector(7 downto 0);
  
begin
  UART_HOST: UART_Unit generic map(FPGA_FREQ, HOST_BAUD, 8, 1, 0, 0) port map(clk, rst, host_send_data, host_write_en, host_full, tx_pin_host, host_received_data, open, open, host_new_data_received, rx_pin_host);
  DECODE: Decoder generic map(8, FPGA_FREQ) port map(clk, rst, host_received_data, host_new_data_received, decode_out_en, decode_access_mode, decode_unit_number, decode_unit_data);
  EN_DEMUX: DEMUX port map(decode_unit_number, decode_out_en, a_en, b_en, open, open, open, open, open, open);

  A_UART: UART_Wrapper generic map(FPGA_FREQ, HOST_BAUD, 8, 1, 0, 0) port map(clk, rst, decode_unit_data, a_en, open, tx_pin_a, a_received_data, open, open, a_new_data_received, rx_pin_a, a_scheduler_done);
  B_GPIO: GPIO_Wrapper generic map(8) port map(clk, rst, b_en, decode_access_mode, decode_unit_data, b_scheduler_wanted, b_scheduler_done, b_values_out, gpio_pins_in, gpio_pins_out);

  SCHEDULE: PriorityScheduler port map(clk, rst, scheduler_schdule_next, scheduler_write_en, schedule_control_sig, a_new_data_received, b_scheduler_wanted, '0', '0', '0', '0', '0', '0', a_scheduler_done, b_scheduler_done, open, open, open, open, open, open);
  SCHED_MUX: MUX generic map(8) port map(schedule_control_sig, a_received_data, b_values_out, (others=>'0'), (others=>'0'), (others=>'0'), (others=>'0'), (others=>'0'), (others=>'0'),  mux_unit_data_out);

  ENCODE: Encoder generic map(8) port map(clk, rst, scheduler_write_en, not host_full, schedule_control_sig, mux_unit_data_out, host_send_data, host_write_en, scheduler_schdule_next);
end Behavioral;
