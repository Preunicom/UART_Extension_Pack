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
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); -- unused
      unit_data_in : in std_logic_vector(DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(DATA_BITS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      TX_pin : out std_logic;
      RX_pin : in std_logic
    );
  end component;
  component GPIO_Wrapper
    Generic (
      IO_PINS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
      unit_data_in : in STD_LOGIC_VECTOR(IO_PINS-1 downto 0);
      unit_data_out : out STD_LOGIC_VECTOR(IO_PINS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
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
      uart_error : in std_logic;
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
      inp : in std_logic_vector(7 downto 0);
      outp : out std_logic_vector(7 downto 0)
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
      outp : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;
  
  -- host send
  signal host_send_data : std_logic_vector(7 downto 0);
  signal host_write_en : std_logic;
  signal host_full : std_logic;
  -- host receive
  signal host_received_data : std_logic_vector(7 downto 0);
  signal host_new_data_received : std_logic;
  signal host_frame_error, host_parity_error : std_logic;
  signal host_any_uart_error : std_logic;
  signal host_empty : std_logic;

  -- decoder
  signal decode_out_en : std_logic;
  signal decoded_access_mode : std_logic_vector(1 downto 0);
  signal decoded_unit_number : std_logic_vector(2 downto 0);
  signal decoded_unit_data : std_logic_vector(7 downto 0);

  -- demux
  signal unit_en : std_logic_vector(7 downto 0);

  -- Units
  signal unit_scheduler_wanted : std_logic_vector(7 downto 0) := (others => '0');
  signal unit_scheduler_done : std_logic_vector(7 downto 0) := (others => '0');
  
  -- a (UART)
  signal unit_data_out_a : std_logic_vector(7 downto 0) := (others => '0');
  -- b (GPIO)
  signal unit_data_out_b : std_logic_vector(7 downto 0) := (others => '0');
  -- c (-)
  signal unit_data_out_c : std_logic_vector(7 downto 0) := (others => '0');
  -- d (-)
  signal unit_data_out_d : std_logic_vector(7 downto 0) := (others => '0');
  -- e (-)
  signal unit_data_out_e : std_logic_vector(7 downto 0) := (others => '0');
  -- f (-)
  signal unit_data_out_f : std_logic_vector(7 downto 0) := (others => '0');
  -- g (-)
  signal unit_data_out_g : std_logic_vector(7 downto 0) := (others => '0');
  -- h (-)
  signal unit_data_out_h : std_logic_vector(7 downto 0) := (others => '0');

  -- scheduler
  signal schedule_control_sig : std_logic_vector(2 downto 0);
  signal scheduler_write_en : std_logic := '0';
  signal scheduler_schedule_next: std_logic;

  -- mux
  signal mux_unit_data_out : std_logic_vector(7 downto 0);
  
begin
  UART_HOST: UART_Unit generic map(FPGA_FREQ, HOST_BAUD, 8, 1, 0, 0) port map(clk, rst, host_send_data, host_write_en, host_full, tx_pin_host, host_received_data, host_frame_error, host_parity_error, host_new_data_received, rx_pin_host);
  DECODE: Decoder generic map(8, FPGA_FREQ) port map(clk, rst, host_received_data, host_new_data_received, host_any_uart_error , decode_out_en, decoded_access_mode, decoded_unit_number, decoded_unit_data);
  EN_DEMUX: DEMUX port map(decoded_unit_number, decode_out_en, unit_en);

  A_UART: UART_Wrapper generic map(FPGA_FREQ, 250000, 8, 1, 0, 0) port map(clk, rst, unit_en(0), decoded_access_mode, decoded_unit_data, unit_data_out_a, unit_scheduler_wanted(0), unit_scheduler_done(0), tx_pin_a, rx_pin_a);
  B_GPIO: GPIO_Wrapper generic map(8) port map(clk, rst, unit_en(1), decoded_access_mode, decoded_unit_data, unit_data_out_b, unit_scheduler_wanted(1), unit_scheduler_done(1), gpio_pins_in, gpio_pins_out);

  SCHEDULE: PriorityScheduler port map(clk, rst, scheduler_schedule_next, scheduler_write_en, schedule_control_sig, unit_scheduler_wanted, unit_scheduler_done);
  SCHED_MUX: MUX generic map(8) port map(schedule_control_sig, unit_data_out_a, unit_data_out_b, unit_data_out_c, unit_data_out_d, unit_data_out_e, unit_data_out_f, unit_data_out_g, unit_data_out_h,  mux_unit_data_out);

  ENCODE: Encoder generic map(8) port map(clk, rst, scheduler_write_en, host_empty, schedule_control_sig, mux_unit_data_out, host_send_data, host_write_en, scheduler_schedule_next);

  host_any_uart_error <= host_frame_error or host_parity_error;
  host_empty <= not host_full;

end Behavioral;
