--! @file
--! @brief UART buffer/register for deserializer.
--! @details Buffers parallel RX data and associated error flags from the deserializer, ensuring they remain stable until consumed by downstream logic.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

--! Entity implementing a buffer for UART reception, holding parallel data and error flags until they are read.
entity Buffer_Register_Deserializer is
  Generic(
    DATA_BITS : integer := 8 --! Number of data bits to buffer.
  );
  Port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    parallel_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel RX data from deserializer.
    frame_error_in : in std_logic; --! Framing error flag from deserializer.
    parity_error_in : in std_logic; --! Parity error flag from deserializer.
    write_en : in std_logic; --! Strobe to load new data and error flags.
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0); --! Buffered RX data output.
    frame_error_out : out std_logic; --! Buffered framing error flag.
    parity_error_out : out std_logic; --! Buffered parity error flag.
    new_data : out std_logic --! Pulse: new RX data available.
  );
end Buffer_Register_Deserializer;

--! Architecture implementing simple register storage for RX data and error flags.
architecture Behavioral of Buffer_Register_Deserializer is
begin

  --! Main buffer process: updates stored RX data and error flags when write_en is asserted, and provides a new_data pulse.
  BUFDES: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        parallel_out <= (others => '0');
        frame_error_out <= '0';
        parity_error_out <= '0';
        new_data <= '0';
      else
        new_data <= '0';
        if write_en = '1' then
          new_data <= '1';
          parallel_out <= parallel_in;
          frame_error_out <= frame_error_in;
          parity_error_out <= parity_error_in;
        end if;
      end if;
    end if;
  end process;

end Behavioral;