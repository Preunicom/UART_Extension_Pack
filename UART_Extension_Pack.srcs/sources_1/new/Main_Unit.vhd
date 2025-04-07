library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.UnitDataArray_Type_PKG.ALL;

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
      unit_data_out : out std_logic_vector(13 downto 0);
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
      unit_data_out : out STD_LOGIC_VECTOR(13 downto 0);
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
      unit_data_out    : out STD_LOGIC_VECTOR(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done   : in  std_logic
    );
  end component;
  component Reset_Unit
    Generic (
      HOST_DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); -- unused
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); 
      unit_data_out : out std_logic_vector(13 downto 0); 
      scheduler_wanted : out std_logic; 
      scheduler_done : in std_logic;
      rst_ext_pack : out std_logic := '0'
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
      clk, rst      : in std_logic;
      control       : in  STD_LOGIC_VECTOR(5 downto 0);
      control_valid : in std_logic;
      inp           : in unit_data_array;
      outp          : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
      mux_unit_number_out : out std_logic_vector(5 downto 0);
      outp_valid    : out std_logic
    );
  end component;
  component DEMUX
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in std_logic;
      control : in STD_LOGIC_VECTOR (5 downto 0);
      inp_en : in STD_LOGIC;
      inp_data : in std_logic_vector(DATA_BITS-1 downto 0);
      outp_en : out STD_LOGIC_VECTOR(63 downto 0);
      outp_data : out std_logic_vector(DATA_BITS-1 downto 0)
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
  signal unit_data_in : std_logic_vector(HOST_DATA_BITS-1 downto 0);

  -- Units
  signal unit_scheduler_wanted : std_logic_vector(63 downto 0) := (others => '0');
  signal unit_scheduler_done : std_logic_vector(63 downto 0) := (others => '0');
  signal unit_data_out : unit_data_array := (others => (others => '0'));

  -- Reset Unit
  signal rst_unit : std_logic := '0';
  signal rst_ext_pack : std_logic := '0';

  -- scheduler
  signal schedule_control_sig : std_logic_vector(5 downto 0);
  signal scheduler_write_en : std_logic := '0';
  signal scheduler_schedule_next: std_logic;

  -- mux
  signal mux_unit_data_out : std_logic_vector(HOST_DATA_BITS-1 downto 0);
  signal mux_unit_number_out : std_logic_vector(5 downto 0);
  signal mux_write_en : std_logic;
  
begin
  UART_HOST: UART_Unit generic map(FPGA_FREQ, HOST_BAUD, HOST_DATA_BITS, HOST_STOP_BITS, HOST_PARITY_ACTIVE, HOST_PARITY_MODE) port map(clk, rst_ext_pack, host_send_data, host_write_en, host_full, tx_pin_host, host_received_data, host_frame_error, host_parity_error, host_new_data_received, rx_pin_host);
  DECODE: Decoder generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst_ext_pack, host_received_data, host_new_data_received, host_any_uart_error, decode_out_en, decoded_access_mode, decoded_unit_number, decoded_unit_data);
  EN_DEMUX: DEMUX port map(clk, rst_ext_pack, decoded_unit_number, decode_out_en, decoded_unit_data, unit_en, unit_data_in);

  ------------- SPECIAL UNITS -------------
  U00_RST: Reset_Unit generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, unit_en(0), decoded_access_mode, unit_data_in, unit_data_out(0), unit_scheduler_wanted(0), unit_scheduler_done(0), rst_unit);

  ------------- CUSTOM UNITS --------------
  U02_UART: UART_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, 250000, 8, 1, 0, 0) port map(clk, rst_ext_pack, unit_en(2), decoded_access_mode, unit_data_in, unit_data_out(2), unit_scheduler_wanted(2), unit_scheduler_done(2), tx_pin_a, rx_pin_a);
  U03_GPIO: GPIO_Wrapper generic map(HOST_DATA_BITS, 1, 2) port map(clk, rst_ext_pack, unit_en(3), decoded_access_mode, unit_data_in, unit_data_out(3), unit_scheduler_wanted(3), unit_scheduler_done(3), gpio_pins_in, gpio_pins_out);
  U04_TIME: Timer_Wrapper generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst_ext_pack, unit_en(4), decoded_access_mode, unit_data_in, unit_data_out(4), unit_scheduler_wanted(4), unit_scheduler_done(4));

  -------------- UNITS END ----------------
  
  SCHEDULE: PriorityScheduler port map(clk, rst_ext_pack, scheduler_schedule_next, scheduler_write_en, schedule_control_sig, unit_scheduler_wanted, unit_scheduler_done);
  SCHED_MUX: MUX generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, schedule_control_sig, scheduler_write_en, unit_data_out, mux_unit_data_out, mux_unit_number_out, mux_write_en);
  ENCODE: Encoder generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, mux_write_en, host_empty, mux_unit_number_out, mux_unit_data_out, host_send_data, host_write_en, scheduler_schedule_next);

  host_any_uart_error <= host_frame_error or host_parity_error;
  host_empty <= not host_full;

  -- resets everything when rst is triggered or rst unit got reset command
  rst_ext_pack <= rst or rst_unit;

end Behavioral;
