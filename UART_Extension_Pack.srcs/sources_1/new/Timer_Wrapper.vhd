--! @file
--! @brief Wrapper for Timer_Unit with scheduler/host interface.
--! @details Allows the host to enable/disable the timer, restart it, set the prescale factor, and set the start value. Schedules a notification on timer end and detects overwrite of pending notifications.
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

--! \defgroup UNIT_WRAPPER ExtPack unit wrapper.
--! @brief Wrapper for units of ExtPack.
--! @{

--! @brief Exposes Timer_Unit control and status to the host via a simple command interface.
--! @details Can be configured via UART (No configuration in VHDL code necessary).\n
--! The timer is an x-bit timer with x being the amount of bits of the host UART communication.\n
--! It counts from a given start value (default 0) up to the maximum value of x bit. The overflow triggers an interrupt which is sent to the host.  
--! The timer frequency the prescaler then works with is at 5% of host baud rate.  
--! @note The reason is, that that is the maximum of ExtPack packages (consists of two UART packages: unit number and unit data) that are being able to be transmitted to the host via 8N1 UART, which is the fastest supported host UART mode when looking at packages transmission rate.  
--! @details The speed of counting (prescaler) can also be set as a divisor of this 5% of host BAUD frequency. (default: 1)\n
--! For example: With a host baud rate of 1 MHz a prescale divisor of 2 results in 25 KHz.\n
--! The access mode handles all this configurations:\n
--! - "00": Enables/disables the timer.\n
--!   - 0 as value disables the timer.\n
--!   - Any value greater than 0 enables the timer.\n
--! - "01": Restarts the timer. (value is ignored)\n
--! - "10": Sets the value as the prescale divisor. (**Note:** Even values lead to a preciser timer)\n
--! - "11": Sets the value as the start value of the timer.
--!
--! @note
--! - Think of the fact, that scheduling and sending the timer overflow interrupt to the host will need some time.\n
--! - As the timer counts even if disabled, because disabling only targets the interrupt, you have to restart the timer to apply the set start value and get the result as expected.  
--! @details **Timer init suggestion:**\n
--! 1) set prescale factor and or start value (the order doesn't matter if the timer is restarted afterwards)\n
--! 2) restart the timer\n
--! 3) enable the timer
--!@details **Timer change suggestion:**\n
--! 1) disable the timer\n
--! 2) init the timer like described above
entity Timer_Wrapper is
--! @}
  generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host data bus in bits.
    FPGA_FREQ : integer := 12000000; --! Input clock frequency in Hz.
    HOST_BAUD : integer := 1000000 --! Host baud rate in bits per second (used to derive default base frequency).
  );
  port (
    clk : in  STD_LOGIC; --! Clock signal.
    rst : in  STD_LOGIC; --! Reset signal.
    write_en         : in  std_logic; --! Host write strobe.
    access_mode      : in  std_logic_vector(1 downto 0); --! 00: enable/disable, 01: restart, 10: set prescale_factor, 11: set start_value.
    unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0); --! Payload from host (value for selected access_mode).
    unit_data_out    : out STD_LOGIC_VECTOR(13 downto 0); --! Data to host (all '1' on timer end).
    scheduler_wanted : out std_logic; --! Request to scheduler for sending unit_data_out.
    scheduler_done   : in  std_logic; --! Scheduler acknowledge of completed send.
    error_to_host    : out std_logic := '0'; --! Error: timer end notification would overwrite a pending one.
    error_from_host  : out std_logic := '0' --! Unused.
  );
end entity;

--! Architecture connecting host commands to Timer_Unit and the scheduler handshake.
architecture Behavioral of Timer_Wrapper is
  --! Component declaration for Timer_Unit.
  component Timer_Unit
    generic (
      WIDTH : integer := 8;
      IN_FREQ : integer := 12000000;
      BASE_FREQ : integer := 50000
    );
    port (
      clk : in std_logic; --! Clock signal.
      rst : in std_logic; --! Reset signal.
      en : in std_logic;
      prescale_factor_write_en : in std_logic;
      prescale_factor : in integer;
      start_value_write_en : in std_logic;
      start_value : in unsigned(WIDTH-1 downto 0);
      restart_timer : in std_logic;
      is_timer_end : out std_logic
    );
  end component;
  --! Enables the timer when set to '1'.
  signal timer_active_int             : std_logic := '0';
  --! Write-enable for updating the prescale factor.
  signal prescale_factor_write_en_int : std_logic := '0';
  --! New prescale factor value from host.
  signal prescaled_factor_int         : integer;
  --! Write-enable for updating the start value.
  signal start_value_write_en_int     : std_logic := '0';
  --! New start value from host.
  signal start_value_int              : unsigned(HOST_DATA_BITS-1 downto 0);
  --! Synchronous restart pulse to Timer_Unit.
  signal restart_timer_int            : std_logic := '0';
  --! Timer end indication from Timer_Unit.
  signal is_timer_end_int             : std_logic := '0';
  --! Previous value of is_timer_end_int for edge detection.
  signal last_is_timer_end_int        : std_logic := '0';
  --! Previous value of scheduler_done for edge detection.
  signal last_scheduler_done          : std_logic := '0';
  --! Indicates a pending scheduler response until scheduler_done.
  signal scheduling_active            : std_logic := '0';
begin
  --! The timer handling the timer features.
  TIMER: Timer_Unit generic map (HOST_DATA_BITS, FPGA_FREQ, HOST_BAUD/20) port map (clk, rst, timer_active_int, prescale_factor_write_en_int, prescaled_factor_int, start_value_write_en_int, start_value_int, restart_timer_int, is_timer_end_int);
  
  --! Host command handler: decodes access_mode and updates Timer_Unit controls.
  WRITE: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        restart_timer_int <= '0';
        prescale_factor_write_en_int <= '0';
        start_value_write_en_int <= '0';
        start_value_int <= (others => '0');
        prescaled_factor_int <= 0;
        timer_active_int <= '0';
      else
        restart_timer_int <= '0';
        if write_en = '1' then
          -- Host wrote a command/value.
          case access_mode is
            when "00" =>
              if unsigned(unit_data_in) > 0 then
                -- Enable timer.
                timer_active_int <= '1';
              else
                -- Disable timer.
                timer_active_int <= '0';
              end if;
            when "01" =>
              -- Restart timer.
              restart_timer_int <= '1';
            when "10" =>
              -- Set prescale factor.
              prescale_factor_write_en_int <= '1';
              prescaled_factor_int <= to_integer(unsigned(unit_data_in));
            when "11" =>
              -- Set start value.
              start_value_write_en_int <= '1';
              start_value_int <= unsigned(unit_data_in);
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process;

  --! Schedules a timer-end notification to the host and detects overwrites.
  TIMER_INTERRUPT: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        scheduling_active <= '0';
        error_to_host <= '0';
      else
        error_to_host <= '0';
        if last_scheduler_done = '0' and scheduler_done = '1' then
          -- Scheduling finished: clear scheduler request and data.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        end if;
        if last_is_timer_end_int = '0' and is_timer_end_int = '1' then
          -- Schedule timer-end notification.
          if scheduling_active = '1' then
            -- Overwriting pending timer notification: raise error.
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out <= (others => '1');
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;
  
  --! Captures previous values for edge detection (is_timer_end_int, scheduler_done).
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_is_timer_end_int <= '0';
        last_scheduler_done <= '0';
      else
        last_is_timer_end_int <= is_timer_end_int;
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;
  
end architecture;
