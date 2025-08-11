--! @file
--! @brief SPI buffer/register for deserializer.
--! @details Buffers parallel RX data from the SPI deserializer and holds it stable until it is read by downstream logic.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Entity implementing a buffer that stores received SPI data until consumption, generating a new_data pulse when updated.
entity SPI_Buffer_Register_Deserializer is
  Generic(
    DATA_BITS : integer := 8 --! Number of data bits to buffer.
  );
  Port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    parallel_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel RX data from SPI deserializer.
    write_en : in std_logic; --! Strobe to load new data into buffer.
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0); --! Buffered RX data output.
    new_data : out std_logic --! Pulse: new data available.
  );
end SPI_Buffer_Register_Deserializer;

--! Architecture implementing simple register storage for SPI RX data.
architecture Behavioral of SPI_Buffer_Register_Deserializer is
begin

  --! Main buffer process: loads new RX data when write_en is asserted and pulses new_data.
  BUFDES: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        parallel_out <= (others => '0');
        new_data <= '0';
      else
        new_data <= '0';
        if write_en = '1' then
          new_data <= '1';
          parallel_out <= parallel_in;
        end if;
      end if;
    end if;
  end process;

end Behavioral;