--! @file
--! @brief SPI clock prescaler.
--! @details Generates rising and falling edge enable pulses for the SPI clock (SCK) at a prescaled rate based on the input clock frequency, SPI mode, and frame length.
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

--! Entity implementing an SPI clock prescaler producing separate rising and falling edge pulses.
entity SPI_Prescaler is
  generic (
    IN_FREQ_HZ  : integer := 12000000; --! Input clock frequency in Hz. @note Condition: IN_FREQ_HZ >= 2x OUT_FREQ_HZ
    OUT_FREQ_HZ : integer := 9600; --! Desired SPI clock frequency in Hz.
    DATA_BITS : integer := 8; --! Number of bits per SPI frame.
    SPI_MODE : integer := 0 --! SPI mode (0..3: defines clock polarity and phase).
  );
  port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    clk_prescaled_rising_edge : out STD_LOGIC; --! Pulse indicating rising edge of prescaled SCK.
    clk_prescaled_falling_edge : out STD_LOGIC --! Pulse indicating falling edge of prescaled SCK.
  );
end entity;

--! Architecture implementing counter-based prescaling to generate SCK edges for SPI communication.
architecture Behavioral of SPI_Prescaler is
  --! Terminal count for prescaler counter to achieve desired SCK frequency.
  constant PRESCALE_COUNTER_END : integer := ((IN_FREQ_HZ + OUT_FREQ_HZ) / (2 * OUT_FREQ_HZ));
  --! Maximum number of SCK edges per SPI frame.
  constant MAX_EDGES : integer  := 2*DATA_BITS;
  --! Current prescaler counter value.
  signal counter                : integer   := 1;
  --! Internal signal tracking current SCK state for edge generation.
  signal clk_prescaled_intern   : std_logic := '0';
  --! Counter for number of edges generated in current frame.
  signal max_edges_counter      : integer   := 2*DATA_BITS;
begin

  --! Main prescaler process: counts input clock cycles, toggles SCK state at target rate, and generates separate rising/falling edge pulses.
  PRESCALER: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        clk_prescaled_falling_edge <= '0';
        clk_prescaled_rising_edge <= '0';
        if SPI_MODE = 0 or SPI_MODE = 1 then
          -- clk low in idle mode --> first edge is rising edge
          clk_prescaled_intern <= '0';
        else 
          -- clk high in idle mode --> first edge is falling edge
          clk_prescaled_intern <= '1';
        end if;
        counter <= 1;
        max_edges_counter <= 0; -- Ensures correct amount of edges on SCK at high transmissions speeds
      else
        counter <= counter + 1;
        clk_prescaled_rising_edge <= '0';
        clk_prescaled_falling_edge <= '0';
        -- integer gets truncated in VHDL
        if counter >= PRESCALE_COUNTER_END and max_edges_counter < MAX_EDGES then
          max_edges_counter <= max_edges_counter + 1;
          clk_prescaled_intern <= not clk_prescaled_intern;
          if clk_prescaled_intern = '1' then
            clk_prescaled_falling_edge <= '1';
          else
            clk_prescaled_rising_edge <= '1';
          end if;
          counter <= 1;
        end if;
      end if;
    end if;
  end process;

end architecture;
