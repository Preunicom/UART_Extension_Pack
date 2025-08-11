--! @file
--! @brief Wrapper for GPIO bank unit with scheduler interface.
--! @details Provides access to GPIO inputs and outputs via host commands. Supports write mode (set outputs) and read mode (get inputs) with scheduler requests when values change or upon host read request.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! \defgroup UNIT_WRAPPER ExtPack unit wrapper
--! @brief Wrapper for units of ExtPack.
--! @{

--! @brief Wraps a GPIO_Bank_Unit and interfaces it with the scheduler and host protocol.
--! @details The access mode controls the type of pins to work with:\n
--! - "00" or "10": Set output pins\n
--! - "01" or "11": Request values of input pins
--! @details If there is an interrupt on a input pin detected a message with the current pin values is sent to the host.  
--! @details There is only one error this unit is sending. It is an error_to_host and it is triggered, when an interrupt is overwritten by the next one.
--! This can be used to identify bouncing faster than the communication.
--! @note
--! - Debouncing is not prevented. Therefore its possible to lose interrupts if they are faster than the scheduling and the UART transmission to the host.\n
--! - The output pins are set to the given values from the host. There is no way to only set **one** specific pin to a value.
entity GPIO_Wrapper is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host data bus in bits.
    IN_PINS : integer := 8; --! Number of GPIO input pins. @note Condition <= HOST_DATA_BITS and >= 1
    OUT_PINS : integer := 8 --! Number of GPIO output pins. @note Condition: <= HOST_DATA_BITS and >= 1
  );
  Port ( 
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Enable signal for the input signals.
    access_mode : in std_logic_vector(1 downto 0); --! Access mode: 00:set outputs, 01:get inputs.
    unit_data_in : in STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0); --! Data from host (output configuration).
    unit_data_out : out STD_LOGIC_VECTOR(13 downto 0); --! Data to host (input pin states).
    scheduler_wanted : out std_logic; --! Request to scheduler for host data send.
    scheduler_done : in std_logic; --! Scheduler acknowledge of completed send.
    error_to_host : out std_logic := '0'; --! Triggered when an pending interrupt is overwritten by another interrupt. @details Can be used to identify possible bouncing.
    error_from_host : out std_logic := '0'; --! Unused in this unit.
    gpio_data_in : in STD_LOGIC_VECTOR (IN_PINS-1 downto 0); --! Current raw GPIO input values.
    gpio_data_out : out STD_LOGIC_VECTOR (OUT_PINS-1 downto 0) --! Driven GPIO output values.
  );
end GPIO_Wrapper;

--! Architecture connecting the GPIO_Bank_Unit with host command decoding and scheduler handshake.
architecture Behavioral of GPIO_Wrapper is
  component GPIO_Bank_Unit
    Generic (
      INPUTS : integer := 8;
      OUTPUTS : integer := 8
    );
    Port (
      clk : in std_logic; --! Clock signal.
      rst : in std_logic; --! Reset signal.
      write_en : in std_logic;
      config_in : in STD_LOGIC_VECTOR(OUTPUTS-1 downto 0);
      values_out : out STD_LOGIC_VECTOR(INPUTS-1 downto 0);
      gpio_data_in : in STD_LOGIC_VECTOR (INPUTS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (OUTPUTS-1 downto 0)
    );
  end component;
  --! Enables write mode in GPIO_Bank_Unit when set.
  signal write_mode_en : std_logic := '0';
  --! Output values to be written to GPIO_Bank_Unit.
  signal write_values : std_logic_vector(OUT_PINS-1 downto 0);
  --! Last latched values sent to host.
  signal last_values_read : std_logic_vector(13 downto 0);
  --! Current GPIO input values extended to 14 bits. (filled with zeros if necessary)
  signal values_read : std_logic_vector(13 downto 0) := (others => '0'); -- Extends with zeros if IO_Pins < HOST_DATA_BITS
  --! Previous write_en for edge detection.
  signal last_write_enable : std_logic := '0';
  --! Previous scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Indicates that a receive transaction is active.
  signal scheduling_active : std_logic := '0';
begin
  GPIO: GPIO_Bank_Unit generic map(IN_PINS, OUT_PINS) port map(clk, rst, write_mode_en, write_values, values_read(IN_PINS-1 downto 0), gpio_data_in, gpio_data_out);

  --! Handles write_en edges and updates write mode/output values based on access_mode.
  OUTPUTS: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        write_mode_en <= '0';
        write_values <= (others => '0');
      else      
        if last_write_enable = '0' and write_en = '1' then
          -- Rising edge of write_en detected.
          -- Default to read mode unless access_mode indicates write.
          write_mode_en <= '0';
          if access_mode(0) = '0' then
            -- Enter write mode.
            write_mode_en <= '1';
            write_values <= unit_data_in(OUT_PINS-1 downto 0);
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Detects input changes or host read requests and schedules data to host.
  INPUTS: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        scheduling_active <= '0';
        error_to_host <= '0';
      else
        error_to_host <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- Scheduling finished: clear scheduler request and data.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        elsif (last_values_read /= values_read) -- Interrupt
          or ((access_mode(0) = '1') and (last_write_enable = '0' and write_en = '1')) then -- new request from host: Get input pin values
            -- Schedule current GPIO input values for host send.
            if scheduling_active = '0' then
              -- Overwriting pending GPIO data: raise error.
              error_to_host <= '1';
            end if;
            scheduler_wanted <= '1';
            unit_data_out <= values_read;
          end if;
      end if;
    end if;
  end process;

  --! Tracks previous values of inputs, write_en, and scheduler_done for edge detection.
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_values_read <= (others => '0');
        last_write_enable <= '0';
        last_scheduler_done <= '0';
      else
        -- Capture current GPIO input values.
        last_values_read <= values_read;
        -- Capture current write_en.
        last_write_enable <= write_en;
        -- Capture current scheduler_done.
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;
  
end Behavioral;
