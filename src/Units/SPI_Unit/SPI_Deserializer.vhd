--! @file
--! @brief SPI deserializer unit.
--! @details Converts serial SPI data from the MISO line into parallel data according to configured bit order. Generates a data_valid pulse when a complete frame is received.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Entity implementing an SPI deserializer with configurable bit order (MSB/LSB first).
entity SPI_Deserializer is
  Generic(
    DATA_BITS : integer := 8; --! Number of bits per SPI frame.
    LSB : integer := 0 --! 0: MSB first; 1: LSB first.
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    clk_en_prescaled : in std_logic; --! SPI clock enable from prescaler.
    rst : in std_logic; --! Reset signal.
    serial_in : in std_logic; --! Serial data input (MISO line).
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0); --! Parallel output data.
    data_valid : out std_logic --! Pulse: new parallel data available.
  );
end SPI_Deserializer;

--! Architecture implementing shift register deserialization according to configured bit order.
architecture Behavioral of SPI_Deserializer is
  --! Shift register storing incoming bits until frame is complete.
  signal reg : std_logic_vector(DATA_BITS-1 downto 0);
  --! Counter tracking number of received bits in current frame.
  signal counter : integer := 1;
begin

  --! Main deserialization process: shifts in bits on each prescaled clock enable, assembles parallel data, and asserts data_valid at frame completion.
  DESER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= 1;
        reg <= (others => '0');
        parallel_out <= (others => '0');
        data_valid <= '0';
      elsif clk_en_prescaled = '1' then
        data_valid <= '0';
        if LSB = 1 then
          reg <= serial_in & reg(DATA_BITS-1 downto 1);
          parallel_out <= serial_in & reg(DATA_BITS-1 downto 1);
        else
          reg <= reg(DATA_BITS-2 downto 0) & serial_in;
          parallel_out <= reg(DATA_BITS-2 downto 0) & serial_in;
        end if;
        counter <= counter + 1;
        if counter = DATA_BITS then
          data_valid <= '1';
          counter <= 1;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
