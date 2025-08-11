--! @file
--! @brief UART buffer/register feeding serializer.
--! @details Buffers parallel data for UART transmission and provides handshake logic with serializer to avoid overwriting data before it is sent.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


--! Entity implementing a parallel data buffer that holds UART TX data until the serializer no longer needs it.
entity Buffer_Register_Serializer is
  Generic(
    DATA_BITS : integer := 8 --! Number of data bits to buffer and forward to serializer.
  );
  Port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    write_enable : in std_logic; --! Strobe to write new data into buffer.
    data_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel input data for transmission.
    data_not_needed_anymore : in std_logic; --! Handshake signal from serializer indicating it has finished sending the current data.
    data_out : out std_logic_vector(DATA_BITS-1 downto 0); --! Buffered data output to serializer.
    full : out std_logic --! Buffer full flag (data pending transmission).
    );
end Buffer_Register_Serializer;


--! Architecture implementing handshake-controlled buffering between TX logic and serializer.
architecture Behavioral of Buffer_Register_Serializer is
  --! Internal buffer register storing current TX data.
  signal data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '1');
  --! Last sampled state of data_not_needed_anymore for edge detection.
  signal last_data_not_needed_anymore : std_logic := '1';
  --! Flag indicating a change in data_not_needed_anymore was detected.
  signal data_not_needed_anymore_change_detected : std_logic := '1';
begin
  
  --! Main buffer process: manages loading of new data when serializer signals it is ready.
  BUFS: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        data_out <= (others => '1');
        full <= '0';
        data <= (others => '1');
        data_not_needed_anymore_change_detected <= '1';
      else
        data_out <= data;
        if (last_data_not_needed_anymore = '0' and data_not_needed_anymore = '1') or data_not_needed_anymore_change_detected = '1' then
          data_not_needed_anymore_change_detected <= '1';
          full <= '0';
          if write_enable = '1' then
            data <= data_in;
            data_out <= data_in;
            full <= '1';
            data_not_needed_anymore_change_detected <= '0';
          end if; 
        end if;
      end if;
    end if;
  end process;

  --! Tracks changes in data_not_needed_anymore signal to trigger buffer reload.
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
