--! @file
--! @brief I2C clock prescaler.
--! @details Generates prescaled clock edges for I2C read and write timing, handling clock stretching by the slave via SCL_in monitoring.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! Entity implementing an I2C clock prescaler with separate read and write enables and SCL open-drain control.
entity I2C_Prescaler is
  generic (
    IN_FREQ_HZ  : integer := 12000000; --! Input clock frequency in Hz. @note Condition: IN_FREQ_HZ >= 4x OUT_FREQ_HZ
    OUT_FREQ_HZ : integer := 100000 --! Desired I2C SCL frequency in Hz.
  );
  port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    clk_en_read : out std_logic; --! Prescaled enable pulse for I2C read phase.
    clk_en_write : out std_logic; --! Prescaled enable pulse for I2C write phase.
    SCL_in : in std_logic; --! Current state of I2C clock line (for clock stretching detection).
    SCL_out : out std_logic --! Internal prescaled SCL signal before open-drain handling.
  );
end I2C_Prescaler;

--! Architecture implementing counter-based prescaling with clock stretching support.
architecture Behavioral of I2C_Prescaler is
  --! Terminal count for prescaler counter to achieve desired SCL frequency.
  constant PRESCALE_COUNTER_END : integer := ((IN_FREQ_HZ + OUT_FREQ_HZ) / (2 * OUT_FREQ_HZ));
  --! Midpoint count for generating read/write enables.
  constant PRESCALE_COUNTER_MID : integer := PRESCALE_COUNTER_END / 2;
  --! Current prescaler counter value.
  signal counter              : integer   := 1;
  --! Internal prescaled clock signal (before open-drain output).
  signal clk_prescaled_intern : std_logic := '0';
  --! Pulse marking a rising edge of the prescaled clock.
  signal clk_rising_edge_intern : std_logic;
begin

  SCL_out <= clk_prescaled_intern;

  --! Main prescaler process: increments counter, generates read/write enables, toggles SCL, and handles clock stretching.
  PRESCALER: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        clk_en_read <= '0';
        clk_en_write <= '0';
        clk_rising_edge_intern <= '0';
        clk_prescaled_intern <= '0';
        counter <= 1;
      else
        counter <= counter + 1;
        clk_en_write <= '0';
        clk_en_read <= '0';
        clk_rising_edge_intern <= '0';
        if clk_rising_edge_intern = '1' then
          if SCL_in = '0' then
            counter <= 1;
            clk_rising_edge_intern <= '1';
          end if;
        end if;
        if counter = PRESCALE_COUNTER_MID then
          if clk_prescaled_intern = '1' then
            clk_en_read <= '1';
          else
            clk_en_write <= '1';
          end if;
        end if;
        if counter >= PRESCALE_COUNTER_END then
          clk_prescaled_intern <= not clk_prescaled_intern;
          if clk_prescaled_intern = '0' then
            clk_rising_edge_intern <= '1';
          end if;
          counter <= 1;
        end if;
      end if;
    end if;
  end process;

end Behavioral;