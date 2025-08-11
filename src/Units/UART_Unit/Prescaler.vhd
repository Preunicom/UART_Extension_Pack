--! @file
--! @brief Prescaler for UART modules.
--! @details Generates a prescaled clock enable signal from an input clock to match the required UART baud rate.

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.STD_LOGIC_UNSIGNED.all;

--! Entity implementing a frequency divider to create a baud-rate clock enable.
entity Prescaler is
  generic (
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz.
    OUT_FREQ_HZ : integer := 9600 --! Desired output clock frequency (baud rate) in Hz.
  );
  port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    clk_en_prescaled : out STD_LOGIC --! Output enable pulse at the desired baud rate.
  );
end entity;

--! Architecture implementing counter-based frequency division.
architecture Behavioral of Prescaler is
  --! Counter start value for half clock cycle to align to mid-bit sampling.
  constant PRESCALE_COUNTER_HALF : integer := ((IN_FREQ_HZ / OUT_FREQ_HZ) / 2) + 2;
  --! Counter terminal value for full period.
  constant PRESCALE_COUNTER_END : integer := (IN_FREQ_HZ / OUT_FREQ_HZ);
  --! Current prescaler counter value.
  signal counter : integer := PRESCALE_COUNTER_HALF;
begin

  --! Main prescaler process: increments counter and generates clk_en_prescaled at the desired baud rate.
  PRESCALER: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Start with half clock cycle until rising_edge
        -- To be able to reset Prescaler at falling edge on UART start bit to get values in the mid of a bit.
        counter <= PRESCALE_COUNTER_HALF;
        clk_en_prescaled <= '0';
      else
        counter <= counter + 1;
        clk_en_prescaled <= '0';
        -- integer gets truncated in VHDL
        if counter >= PRESCALE_COUNTER_END then
          clk_en_prescaled <= '1';
          counter <= 1;
        end if;
      end if;
    end if;
  end process;

end architecture;