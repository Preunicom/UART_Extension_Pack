--! @file
--! @brief Reset control unit for the external package.
--! @details Triggers a one-cycle reset signal when a specific compare value is received from the host. Notifies the host via scheduler when a reset has been triggered.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! \defgroup SPECIAL_UNIT Special ExtPack units
--! @brief Special units of ExtPack.
--! @{

--! @brief Provides host-controlled reset of the external package and communicates reset events back to the host.
--! @details This unit should have the unit number zero as it needs the highest scheduling priority.
--! This unit tells the host if the ExtPack got reset with the highest possible unit data value as command data.  
--! Additionally, it is possible to reset the ExtPack by sending the highest possible unit data value to the Reset_Unit (unit zero).
entity Reset_Unit is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8 --! Width of the host data bus in bits.
  );
  Port ( 
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Host write strobe.
    access_mode : in std_logic_vector(1 downto 0); --! 00: Reset, others: ignored
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Data from host to compare with reset trigger value.
    unit_data_out : out std_logic_vector(13 downto 0); --! Data to host indicating reset event (all bits '1').
    scheduler_wanted : out std_logic; --! Request to scheduler for sending reset event.
    scheduler_done : in std_logic; --! Scheduler acknowledge of completed send.
    error_to_host : out std_logic := '0'; --! Unused.
    error_from_host : out std_logic := '0'; --! Error triggered when an access mode not 00 is used.
    rst_ext_pack : out std_logic := '0' --! One-cycle reset signal to the external package.
  );
end Reset_Unit;

--! Architecture implementing reset trigger detection, host notification, and edge detection logic.
architecture Behavioral of Reset_Unit is
  --! Compare value that triggers reset when matched by unit_data_in.
  signal rst_cmp_value : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '1');
  --! Previous value of write_en for edge detection.
  signal last_write_enable : std_logic := '0';
  --! Previous value of scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Indicates that a reset has been triggered and not yet reported to the host.
  signal rst_triggered : std_logic := '1';
begin

  --! Detects write_en rising edge and asserts rst_ext_pack if unit_data_in matches rst_cmp_value.
  SET_RST: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rst_ext_pack <= '0';
        error_from_host <= '0';
      else  
        rst_ext_pack <= '0';    
        error_from_host <= '0';
        if last_write_enable = '0' and write_en = '1' then
          if access_mode = "00" then
            -- Rising edge of write_en detected.
            if unit_data_in = rst_cmp_value then
              -- Send one-cycle reset pulse to external package.
              rst_ext_pack <= '1';
            end if;
          else
            -- Invalid access mode chosen.
            error_from_host <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Notifies host via scheduler when a reset has been triggered. Clears notification once acknowledged.
  GET_RST: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        -- Reset was triggered
        rst_triggered <= '1';
      else
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- Scheduling finished: clear scheduler request and reset notification.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          rst_triggered <= '0';
        elsif rst_triggered = '1' then
          -- Request scheduler to send reset notification to host.
          scheduler_wanted <= '1';
          unit_data_out <= (others => '1');
          rst_triggered <= '0';
        end if;
      end if;
    end if;
  end process;

  --! Captures previous values of write_en and scheduler_done for edge detection.
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_enable <= '0';
        last_scheduler_done <= '0';
      else
        -- Capture current write_en.
        last_write_enable <= write_en;
        -- Capture current scheduler_done.
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;
