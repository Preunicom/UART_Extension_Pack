--! @file
--! @brief SPI buffer/register feeding serializer.
--! @details Buffers parallel TX data for SPI transmission and coordinates handshaking with the serializer to prevent data overwrite until transmission is complete.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--! Entity implementing a parallel TX buffer that stores data until the serializer signals it is no longer needed.
entity SPI_Buffer_Register_Serializer is
  Generic(
    DATA_BITS : integer := 8 --! Number of data bits to buffer for SPI transmission.
  );
  Port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    write_enable : in std_logic; --! Strobe to write new data into buffer.
    data_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel input data to buffer.
    data_not_needed_anymore : in std_logic; --! Handshake signal from serializer indicating data has been fully transmitted.
    data_out : out std_logic_vector(DATA_BITS-1 downto 0); --! Buffered data output to serializer.
    full : out std_logic --! Buffer full flag (data pending transmission).
    );
end SPI_Buffer_Register_Serializer;

--! Architecture implementing handshake-controlled buffering between TX logic and serializer.
architecture Behavioral of SPI_Buffer_Register_Serializer is
  --! Internal register storing current TX data.
  signal data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '1');
  --! Last sampled state of data_not_needed_anymore for edge detection.
  signal last_data_not_needed_anymore : std_logic := '1';
begin
  --! Main buffer process: manages loading of new data when serializer signals it has finished transmission.
  BUFS: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Clear outputs
        data_out <= (others => '1');
        full <= '0';
        -- Clear intern data
        data <= (others => '1');
      else
        -- Set default outputs
        -- Default case:
        -- current data not sent
        --> Wait for current data sent
        data_out <= data;
        if (last_data_not_needed_anymore = '0' and data_not_needed_anymore = '1') then
          -- current data completelysent
          --> Wait for new data
          full <= '0'; --> automatically sets write enable to false at shift reg
        end if;
        if write_enable = '1' then
          -- new data available to load (Can overwrite current data, to prevent getting blocked in context of SPI Unit)
          --> Get data from input
          data <= data_in;
          data_out <= data_in;
          -- Set full flag --> Set write enable for shift reg
          full <= '1';
        end if; 
      end if;
    end if;
  end process;

  --! Tracks changes in data_not_needed_anymore signal for handshake purposes.
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_data_not_needed_anymore <= '1';
      else
       last_data_not_needed_anymore <= data_not_needed_anymore;
      end if;
    end if;
  end process;

end Behavioral;
