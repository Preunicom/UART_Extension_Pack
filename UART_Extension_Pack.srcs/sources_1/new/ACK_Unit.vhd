--! @file
--! @brief Acknowledge unit that reflects received data back to the host on request.
--! @details Provides an ACK mechanism. When active, incoming data is echoed back.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

--! \defgroup SPECIAL_UNIT Special ExtPack units
--! @brief Special units of ExtPack.
--! @{

--! @brief Echoes data back to host when enabled and raises an error on ACK overwrite while a previous schedule is active.
--! @details The Acknowledge Unit sends, if activated, every received data package back to the host. 
--! The host then can for example check if the data was correctly received.
--! The ACK unit can be activated by sending a number unequal zero to the unit.
--! If sent zero the unit gets deactivated.
--! @note Both packages activate and deactivate send acknowledges to the host.
--! @note The unit has to get the decoder output enable signal as "write_en" as it should react to all units' data.
--! The signal is internally delayed by one clock cyle to match the unit data.
--! The "unit_number" parameter is the decoded unit number from the decoder output.
entity ACK_Unit is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host data bus in bits.
    ACK_UNIT_NUMBER : integer := 2 --! Unit number that selects this ACK unit (matches incoming unit_number).
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal. (active high)
    write_en : in std_logic; --! Enable signal for the input data.
    access_mode : in std_logic_vector(1 downto 0); --! Access mode from host (unused - Needed to have same ports for all units).
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Incoming payload from host.
    unit_data_out : out std_logic_vector(13 downto 0); --! Echo payload towards scheduler/host (zero-extended).
    scheduler_wanted : out std_logic; --! Request line to schedule this unit's output.
    scheduler_done : in std_logic; --! Acknowledge from scheduler that the request has been processed.
    error_to_host : out std_logic := '0'; --! Error flag: set when a new ACK would overwrite a pending one.
    error_from_host : out std_logic := '0'; --! Error flag from host side (unused - Needed to have same ports for all units).
    unit_number : in std_logic_vector(5 downto 0) --! Target unit number from host (0..63).
  );
end ACK_Unit;

--! Architecture implementing the ACK enable/echo logic and scheduler handshake.
architecture Behavioral of ACK_Unit is
  --! Previous value of scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Enables echoing of incoming data when set to '1'.
  signal enable_ack : std_logic := '0';
  --! Zero-extension prefix to widen HOST_DATA_BITS to 14 bits for unit_data_out.
  constant unit_data_out_prefix : std_logic_vector(13 downto HOST_DATA_BITS) := (others => '0');
  --! Indicates that an ACK packet is currently requested to send but not yet completed.
  signal scheduling_active : std_logic := '0';
  --! Write enable delayed by one cycle to align with DEMUX-latency of unit_data_in.
  signal write_en_delayed : std_logic := '0'; --!
begin

  --! Main ACK process: handles enable, echoing data, scheduler requests, and overwrite detection.
  ACKNOWLEDGE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        enable_ack <= '0';
        scheduling_active <= '0';
      else  
        error_to_host <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- Scheduling finished: clear request and outputs.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        end if;
        if write_en_delayed = '1' then
          -- New data received.
          if enable_ack = '1' then
            -- ACK enabled: echo received message.
            scheduler_wanted <= '1';
            unit_data_out <= unit_data_out_prefix & unit_data_in;
            scheduling_active <= '1';
            if scheduling_active = '1' then
              -- Overwriting pending ACK: raise error.
              error_to_host <= '1';
            end if;
          end if;
          if to_integer(unsigned(unit_number)) = ACK_UNIT_NUMBER then
            -- Command addressed to ACK unit.
            if unsigned(unit_data_in) = 0 then
              enable_ack <= '0';
            else
              enable_ack <= '1';
              scheduler_wanted <= '1';
              unit_data_out <= unit_data_out_prefix & unit_data_in;
              scheduling_active <= '1';
              if scheduling_active = '1' then
                -- Overwriting pending ACK: raise error.
                error_to_host <= '1';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Register/edge process: delays write_en and captures scheduler_done.
  REG: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_scheduler_done <= '0';
        write_en_delayed <= '0';
      else
        -- Align strobes with data and remember previous done.
        write_en_delayed <= write_en;
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;