--! @file
--! @brief SPI serializer unit.
--! @details Converts parallel SPI frame data into a serialized bitstream for MOSI transmission. Supports configurable bit order (MSB/LSB first) and SPI modes.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Entity implementing an SPI serializer with configurable bit order and clock phase alignment.
entity SPI_Serializer is
  Generic(
    DATA_BITS : integer := 8; --! Number of bits per SPI frame.
    SPI_MODE : integer := 0; --! SPI mode (0..3: defines clock polarity and phase).
    LSB : integer := 0 --! 0: MSB first; 1: LSB first.
  );
  Port (
    clk : in std_logic; --! Clock signal.
    clk_en_prescaled : in std_logic; --! SPI clock enable from prescaler.
    rst : in std_logic; --! Reset signal.
    write_enable : in std_logic; --! Strobe to load new parallel data.
    parallel_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel data input for SPI transmission.
    serial_out : out std_logic := '0'; --! Serialized data output (MOSI line).
    buffer_data_saved : out std_logic --! Pulse: data loaded into serializer buffer.
  );
end SPI_Serializer;

--! Architecture implementing shift register serialization according to SPI mode and bit order.
architecture Behavioral of SPI_Serializer is
  --! Shift register holding SPI frame bits.
  signal reg : std_logic_vector(DATA_BITS-1 downto 0) := (others => '1');
  --! Bit counter tracking transmission progress.
  signal counter : integer := DATA_BITS;
begin

  --! Main serialization process: shifts out bits according to configured bit order and SPI mode, loads new data when available.
  SER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Clear intern data
        reg <= (others => '0');
        counter <= DATA_BITS;
        buffer_data_saved <= '0';
        serial_out <= '0';
      elsif clk_en_prescaled = '1' then
        -- Set default values
        --> Valid output for only one clock cycle 
        buffer_data_saved <= '0';
        counter <= counter + 1;
        if LSB = 1 then
          -- Shift the shift register (LSB --> shift left and put 0 to highest bit)
          reg <= '0' & reg(DATA_BITS-1 downto 1);
          -- Last new reg is output
          serial_out <= reg(1);
        else
          -- Shift the shift register (MSB --> shift right and put 0 to lowest bit)
          reg <= reg(DATA_BITS-2 downto 0) & '0';
          -- First new reg is output
          serial_out <= reg(DATA_BITS-2);
        end if;
        if (counter >= DATA_BITS - 1 and (SPI_MODE = 1 or SPI_MODE = 3)) or (counter >= DATA_BITS and (SPI_MODE = 0 or SPI_MODE = 2)) then
          -- reg empty (Shifted last bit out or shifted one zero after last bit out in modes with one more send edge than receive edge)
          if write_enable = '1' then
            -- new data given
            reg <= parallel_in;
            if LSB = 1 then
              -- Last new reg is output
              serial_out <= parallel_in(0);
            else
              -- First new reg is output
              serial_out <= parallel_in(DATA_BITS-1);
            end if;
            -- reset counter
            counter <= 0;
            -- set buffer data saved output
            buffer_data_saved <= '1';
          else
            -- no new data given
            -- Set counter to max value
            counter <= DATA_BITS;
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;