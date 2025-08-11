--! @file
--! @brief External Package (ExtPack) management core.
--! @details Orchestrates host UART I/O, packet decode, unit dispatch via DEMUX/MUX, special units (Reset, Error, ACK), priority scheduling, and final encoding back to the host.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.UnitDataArray_Type_PKG.ALL;

--! Top-level management entity wiring host interface, units and scheduler.
--! @details Used to adapt basic functionallity of ExtPack to custom needs of units.
entity ExtPack_Management is
  Generic(
    FPGA_FREQ : integer := 12000000; --! Input clock frequency in Hz. 
    HOST_BAUD : integer := 1000000; --! Host UART baud rate in bit/s.
    HOST_DATA_BITS : integer := 8;  --! Host payload width in bits. @note Conditon: >= 8 (2 access mode + 6 unit number) and HOST_DATA_BITS + HOST_STOP_BITS + HOST_PARITY_ACTIVE <= 15.
    HOST_STOP_BITS : integer := 1;  --! Number of host stop bits.
    HOST_PARITY_ACTIVE : integer := 0; --! Parity enable of communication with host (0: No parity; 1: Parity enabled).
    HOST_PARITY_MODE : integer := 0   --! Parity mode used to communicate with hose (0: Even parity; 1: Odd parity).
  );
  Port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    unit_en : out std_logic_vector(63 downto 3); --! Per-unit enable signal for access_mode and unit data received for units 3...63. (0...2 are special units)
    decoded_access_mode : out std_logic_vector(1 downto 0); --! Access mode decoded from host command.
    unit_data_received : out std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Broadcast of received host payload to units.
    unit_data_send : in unit_data_array; --! Per-unit payloads to be sent to host. 
    unit_scheduler_wanted : in std_logic_vector(63 downto 3); --! Per-unit request lines to scheduler.
    unit_scheduler_done : out std_logic_vector(63 downto 3); --! Per-unit done acknowledgements from scheduler.
    error_to_host : in std_logic_vector(63 downto 3); --! Per-unit errors to host.
    error_from_host : in std_logic_vector(63 downto 3); --! Per-unit errors from host.
    rx_pin_host_synced : in std_logic; --! UART RX from host (synchronized).
    tx_pin_host : out std_logic; --! UART TX to host.
    rst_system : out std_logic --! System reset output from Reset_Unit or global reset.
  );
end ExtPack_Management;

--! Architecture integrating UART, decoder/encoder, DEMUX/MUX, special units and the priority scheduler.
architecture Behavioral of ExtPack_Management is
  --! Component declaration for the UART_Unit.
  component UART_Unit
    Generic (
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0;
      PARITY_MODE : integer := 0
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
  --! Component declaration for the Decoder.
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
      recv_error : out std_logic;
      access_mode : out std_logic_vector(1 downto 0);
      unit_number : out std_logic_vector(5 downto 0); 
      unit_data : out std_logic_vector(DATA_BITS-1 downto 0)
    );
  end component;
  --! Component declaration for the DEMUX.
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
  --! Component declaration for the Reset_Unit.
  component Reset_Unit
    Generic (
      HOST_DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); 
      unit_data_out : out std_logic_vector(13 downto 0); 
      scheduler_wanted : out std_logic; 
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      rst_ext_pack : out std_logic := '0'
    );
  end component;
  --! Component declaration for the Error_Unit.
  component Error_Unit
    Generic (
      HOST_DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      units_error_to_host : in std_logic_vector(63 downto 0);
      decoder_error : in std_logic;
      units_error_from_host : in std_logic_vector(63 downto 0)
    );
  end component;
  --! Component declaration for the ACK_Unit.
  component ACK_Unit
    Generic (
      HOST_DATA_BITS : integer := 8;
      ACK_UNIT_NUMBER : integer := 2
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); 
      unit_data_out : out std_logic_vector(13 downto 0); 
      scheduler_wanted : out std_logic; 
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      unit_number : in std_logic_vector(5 downto 0)
    );
  end component;
  --! Component declaration for the PriorityScheduler.
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
  --! Component declaration for the MUX.
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
  --! Component declaration for the Encoder.
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
  
  --! @brief Subdata type for unit data used for outputs of the units to give the data to send to the scheduler. 
  --! @details Array of std_logic_vector with a width of 14 bits used to be able to use this array for the maximum length of UART packages possible.
  subtype unit_data_array_t is unit_data_array(63 downto 0);

  -- host send
  --! The scheduled data package sent to the host next. Only one half of the command.
  signal host_send_data : std_logic_vector(HOST_DATA_BITS-1 downto 0);
  
  --! Enable signal for host_send_data.
  signal host_write_en : std_logic;
  
  --! Signalizes if the UART_Unit is ready to send the next byte.
  signal host_full : std_logic;

  -- host receive

  --! The data received from the host via UART. (One part of the command)
  signal host_received_data : std_logic_vector(HOST_DATA_BITS-1 downto 0);
  
  --! Enable strobe signal for the host_received_data signal.
  signal host_new_data_received : std_logic;
  
  --! Frame error of the currently received host UART package.
  signal host_frame_error : std_logic;
  
  --! Parity error of the currently received host UART data.
  signal host_parity_error : std_logic;
  
  --! Any UART error of the currently received host UART data.
  signal host_any_uart_error : std_logic;
 
  --! Signalizes the decoder to send the next data package via UART to the host.
  signal host_empty : std_logic;

  -- decoder

  --! Enable signal for the output signals of the decoder. (decoded_access_mode_internal, decoded_unit_number, decoded_unit_data)
  signal decode_out_en : std_logic;

  --! The decoded access mode of the received command from the host.
  signal decoded_access_mode_internal : std_logic_vector(1 downto 0);

  --! The decoded unit number of the received command from the host.
  signal decoded_unit_number : std_logic_vector(5 downto 0);

  --! The decoded unit data of the received command from the host.
  signal decoded_unit_data : std_logic_vector(HOST_DATA_BITS-1 downto 0);

  -- demux

  --! @brief Enable signal vector for the unit input (received command parts from the host). 
  --! @details The n-th bit addresses the n-th unit.
  signal unit_en_internal : std_logic_vector(63 downto 0);

  --! @brief The delayed decoded unit data of the received command from the host. 
  --! @details Delayed for one clock cycle to match the enable signal.
  signal unit_data_received_internal : std_logic_vector(HOST_DATA_BITS-1 downto 0);

  -- Units

  --! @brief The schedule requests of the units. Enable signals for unit_data_send_internal. 
  --! @details The n-th bit addresses the n-th unit and therefore the n-th unit output/send data.
  signal unit_scheduler_wanted_internal : std_logic_vector(63 downto 0) := (others => '0');

  --! @brief The schedule acknowledge for the units. Acknowledges that the data was processed and sent.
  --! @details The n-th bit addresses the n-th unit.
  signal unit_scheduler_done_internal : std_logic_vector(63 downto 0) := (others => '0');

  --! @brief The data the units want to send. 
  --! @details The n-th vector of the array addresses the n-th unit.
  signal unit_data_send_internal : unit_data_array_t := (others => (others => '0'));

  -- Reset Unit

  --! The reset signal output of the Reset_Unit. Requests an reset for the whole system if set high.
  signal rst_unit : std_logic := '0';

  --! The global reset signal combining the reset request put out from the Reset_Unit and the hardware reset of the FPGA.
  signal rst_ext_pack : std_logic := '0';

  -- Error Unit

  --! Indicator for errors of the decoder.
  signal decoder_recv_error : std_logic := '0';

  --! @brief Indicators for processing errors in the units in the direction of processing data to the host. (Sending commands to host)
  --! @details The n-th bit of the vector addresses the n-th unit.
  signal error_to_host_internal : std_logic_vector(63 downto 0) := (others => '0');

  --! @brief Indicators for processing errors in the units in the direction of processing data from the host. (Receiving commands from host)
  --! @details The n-th bit of the vector addresses the n-th unit.
  signal error_from_host_internal : std_logic_vector(63 downto 0) := (others => '0');

  -- Scheduler

  --! The control signal from the scheduler to the MUX showing the unit number to send the data from next.
  signal schedule_control_sig : std_logic_vector(5 downto 0);

  --! Enable signal for the control signal output of the scheduler.
  signal scheduler_write_en : std_logic := '0';

  --! Strobe signal for the scheduler to schedule the next unit data for sending.
  signal scheduler_schedule_next: std_logic;

  -- mux

  --! The unit data to send next.
  signal mux_unit_data_send : std_logic_vector(HOST_DATA_BITS-1 downto 0);

  --! The unit number to send next.
  signal mux_unit_number_send : std_logic_vector(5 downto 0);

  --! Enable signal for the unit number and unit data from the MUX output and encoder input.
  signal mux_write_en : std_logic;

begin
  -------- DATA RECV & PREPERATION --------

  --! Handles the UART communication between ExtPack and host.
  UART_HOST: UART_Unit generic map(FPGA_FREQ, HOST_BAUD, HOST_DATA_BITS, HOST_STOP_BITS, HOST_PARITY_ACTIVE, HOST_PARITY_MODE) port map(clk, rst_ext_pack, host_send_data, host_write_en, host_full, tx_pin_host, host_received_data, host_frame_error, host_parity_error, host_new_data_received, rx_pin_host_synced);
  
  --! Decodes the received data from the host over the UART_Unit in access mode, unit number and unit data. Also checks for UART errors.
  DECODE: Decoder generic map(HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD) port map(clk, rst_ext_pack, host_received_data, host_new_data_received, host_any_uart_error, decode_out_en, decoder_recv_error, decoded_access_mode_internal, decoded_unit_number, decoded_unit_data);
  
  --! Enables the matching unit to process the received command from host decoded by the Decoder. Delays the unit data to match the enable signal timing.
  EN_DEMUX: DEMUX port map(clk, rst_ext_pack, decoded_unit_number, decode_out_en, decoded_unit_data, unit_en_internal, unit_data_received_internal);

  ------------- SPECIAL UNITS -------------

  --! Special unit zero: Reset_Unit. Communicates resets of the ExtPack to the host and handles reset requests from the host.
  U00_RST: Reset_Unit generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, unit_en_internal(0), decoded_access_mode_internal, unit_data_received_internal, unit_data_send_internal(0), unit_scheduler_wanted_internal(0), unit_scheduler_done_internal(0), error_to_host_internal(0), error_from_host_internal(0), rst_unit);
  
  --! Special unit one: Error_Unit. Sends Errors of the units or decoder errors to the host.
  U01_ERR: Error_Unit generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, unit_en_internal(1), decoded_access_mode_internal, unit_data_received_internal, unit_data_send_internal(1), unit_scheduler_wanted_internal(1), unit_scheduler_done_internal(1), error_to_host_internal(1), error_from_host_internal(1), error_to_host_internal, decoder_recv_error, error_from_host_internal);
  
  --! Special unit two: ACK_Unit. If activated echos all command data received from the host by the ExtPack back to the host.
  U02_ACK: ACK_Unit generic map(HOST_DATA_BITS, 2) port map(clk, rst_ext_pack, decode_out_en, decoded_access_mode_internal, unit_data_received_internal, unit_data_send_internal(2), unit_scheduler_wanted_internal(2), unit_scheduler_done_internal(2), error_to_host_internal(2), error_from_host_internal(2), decoded_unit_number);
  
  -------- DATA PREPERATION & SEND --------

  --! Schedules the next unit data of units requesting their data to be sent.
  SCHEDULE: PriorityScheduler port map(clk, rst_ext_pack, scheduler_schedule_next, scheduler_write_en, schedule_control_sig, unit_scheduler_wanted_internal, unit_scheduler_done_internal);
  
  --! Multiplexes the chosen unit from the scheduler to the encoder.
  SCHED_MUX: MUX generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, schedule_control_sig, scheduler_write_en, unit_data_send_internal, mux_unit_data_send, mux_unit_number_send, mux_write_en);
  
  --! Encodes the unit data and unit number to a valid ExtPack command.
  ENCODE: Encoder generic map(HOST_DATA_BITS) port map(clk, rst_ext_pack, mux_write_en, host_empty, mux_unit_number_send, mux_unit_data_send, host_send_data, host_write_en, scheduler_schedule_next);

  host_any_uart_error <= host_frame_error or host_parity_error;
  host_empty <= not host_full;

  -- Reset the whole system when the ExtPack is reset either on system or by an command of the host.
  rst_ext_pack <= rst or rst_unit;

  -- Map internal signals to ports
  unit_en <= unit_en_internal(63 downto 3);
  decoded_access_mode <= decoded_access_mode_internal;
  unit_data_received <= unit_data_received_internal;
  unit_data_send_internal(63 downto 3) <= unit_data_send(63 downto 3);
  unit_scheduler_wanted_internal(63 downto 3) <= unit_scheduler_wanted;
  unit_scheduler_done <= unit_scheduler_done_internal(63 downto 3);
  error_from_host_internal(63 downto 3) <= error_from_host;
  error_to_host_internal(63 downto 3) <= error_to_host;
  rst_system <= rst_ext_pack;
  
end Behavioral;