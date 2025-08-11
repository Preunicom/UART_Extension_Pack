--! @file
--! @brief Error aggregation unit that reports system error flags to the host.
--! @details Latches error sources (per‑unit to/from host and decoder) and, when any is present, requests scheduling to send a 3‑bit error summary to the host. Clears latched errors after a completed scheduler transaction.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! \defgroup SPECIAL_UNIT Special ExtPack units
--! @brief Special units of ExtPack.
--! @{

--! @brief Collects error indications and exposes them to the host via the scheduler interface.
--! @details The unit one is the error unit. It handles errors of all units and sends status messages to the host about these errors.\n
--! The message structure is shown in the following:\n
--! - Bit 0: Indicates a UART error when receiving UART data from the host.\n
--! - Bit 1: Indicates an error of any unit while sending data to host. (for example because of too slow scheduling)\n
--! - Bit 2: Indicates an error of any unit while processing data from the host. (for example when the UART Unit can not send data as the unit still processes the last data)\n
--! All other bits are zero.
entity Error_Unit is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8 --! Width of the host data bus in bits.
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal. (active high)
    write_en : in std_logic; --! Unused in this unit.
    access_mode : in std_logic_vector(1 downto 0); --! Unused in this unit.
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Unused in this unit.
    unit_data_out : out std_logic_vector(13 downto 0); --! Error summary payload (bits[2:0] = {from_host, to_host, decoder}).
    scheduler_wanted : out std_logic; --! Request line to schedule transmission of the error summary.
    scheduler_done : in std_logic; --! Acknowledge from scheduler that the transmission is complete.
    error_to_host : out std_logic := '0'; --! Unused in this unit.
    error_from_host : out std_logic := '0'; --! Unused in this unit.
    units_error_to_host : in std_logic_vector(63 downto 0); --! Vector of per‑unit errors occurring while sending data to the host.
    decoder_error : in std_logic; --! Error flag from the UART decoder.
    units_error_from_host : in std_logic_vector(63 downto 0) --! Vector of per‑unit errors detected on data received from the host.
  );
end Error_Unit;

--! Architecture implementing error latching, scheduler handshake, and summary generation.
architecture Behavioral of Error_Unit is
  --! Previous value of scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Latched indication: at least one unit reported an error while sending to host.
  signal is_error_present_to_host : std_logic := '0';
  --! Latched indication: at least one unit reported an error from host data.
  signal is_error_present_from_host : std_logic := '0';
  --! Latched indication: decoder signaled an error.
  signal is_error_of_decoder_present : std_logic := '0';
  --! One‑cycle pulse to clear latched error indications after a completed send.
  signal rst_errors_valid : std_logic := '0';
  --! Remembers that rst_errors_valid was asserted to create a full‑cycle clear.
  signal last_rst_errors_valid_set : std_logic := '0';
  --! Upper bits of the 14‑bit payload; kept zero, lower bits carry the 3 error flags.
  signal suffix : std_logic_vector(13 downto 3) := (others => '0');
begin

  --! Error detection/latching process: samples inputs and updates latched error flags.
  ERROR_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        -- Clear all latched error indications.
        is_error_present_to_host <= '0';
        is_error_present_from_host <= '0';
        is_error_of_decoder_present <= '0';
      else
        -- Global clear after successful transmission.
        if rst_errors_valid = '1' then
          is_error_present_to_host <= '0';
          is_error_present_from_host <= '0';
          is_error_of_decoder_present <= '0';
        end if;
        if unsigned(units_error_from_host) > 0 then
          is_error_present_from_host <= '1';
        end if;
        if unsigned(units_error_to_host) > 0 then
          is_error_present_to_host <= '1';
        end if;
        if decoder_error = '1' then
          is_error_of_decoder_present <= '1';
        end if;
      end if;
    end if;
  end process;

  --! Scheduling process: sends the 3‑bit error summary when any error is present; clears after `scheduler_done`.
  SCHEDULE_ERROR: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        rst_errors_valid <= '0';
        last_rst_errors_valid_set <= '0';
      else
        rst_errors_valid <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- Scheduling finished: clear request, payload, and prepare to clear latched errors.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          rst_errors_valid <= '1';
          last_rst_errors_valid_set <= '1';
        elsif last_rst_errors_valid_set = '1' then
          -- One cycle spacer to ensure clear takes effect.
          last_rst_errors_valid_set <= '0';
        elsif (is_error_of_decoder_present = '1') or (is_error_present_from_host = '1') or (is_error_present_to_host = '1') then
          -- Send error summary to host.
          scheduler_wanted <= '1';
          unit_data_out <= suffix & is_error_present_from_host & is_error_present_to_host & is_error_of_decoder_present;
        end if;
      end if;
    end if;
  end process;

  --! Edge detection process: captures previous value of scheduler_done.
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_scheduler_done <= '0';
      else
        -- Update edge-detection register with current scheduler_done.
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;
