--! @file
--! @brief UART serializer unit.
--! @details Converts parallel UART frame data (including start, stop, and optional parity bits) into a serialized bitstream. Supports configurable data bits, stop bits, and parity mode.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--! Entity implementing a UART serializer for transmission.
entity Serializer is
  Generic(
    DATA_BITS : integer := 8; --! Number of data bits per frame. @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    STOP_BITS : integer := 1; --! Number of stop bits. @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_ACTIVE : integer := 0; --! 0: No parity; 1: Parity bit enabled (even/odd as per PARITY_MODE). @note Condition: DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_MODE : integer := 0 --! 0: Even parity; 1: Odd parity.
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    clk_en_prescaled : in std_logic; --! Baud-rate prescaled clock enable.
    rst : in std_logic; --! Reset signal.
    write_enable : in std_logic; --! Strobe to load new parallel data.
    parallel_in : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel data input for serialization.
    serial_out : out std_logic; --! Serial bitstream output.
    buffer_data_saved : out std_logic --! Pulse: data accepted into serializer buffer.
  );
end Serializer;

--! Architecture implementing a shift register with optional parity insertion.
architecture Behavioral of Serializer is
  --! Shift register holding start, data, parity, and stop bits.
  signal reg : std_logic_vector(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto 0) := (others => '1'); -- data + stop + start + parity bits
  --! Bit counter for serialization progress.
  signal counter : std_logic_vector(3 downto 0) := (others => '1');
  --! Constant vector of stop bits to append to frame.
  constant stop_bits_suffix : std_logic_vector(STOP_BITS-1 downto 0) := (others => '1');
begin

  --! Main serializer process: handles reset, shifting, parity calculation, and loading of new frames.
  SER: process(clk, rst)
    variable parity : std_logic; -- 0: Even number of ones; 1: Odd number of ones
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Clear intern data
        parity := '0';
        reg <= (others => '1');
        counter <= (others => '1');
        -- Clear outputs
        serial_out <= '1';
        buffer_data_saved <= '0';
      elsif clk_en_prescaled = '1' then
        -- Set default values
        --> Valid output for only one clock cycle 
        buffer_data_saved <= '0';
        counter <= counter + 1;
        parity := '0';
        -- Shift the shift register (LSB --> shift left and put 1 to highest bit)
        reg <= '1' & reg(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto 1);
        -- Set output to least significant bit of reg
        serial_out <= reg(0);
        if counter >= DATA_BITS+STOP_BITS+PARITY_ACTIVE then
          -- reg empty (Shifted last bit out)
          if write_enable = '1' then
            -- new data given
            if PARITY_ACTIVE = 1 then
              -- Calculate parity
              for i in 0 to DATA_BITS-1 loop
                parity := parity xor parallel_in(i);
              end loop;
              -- Add parity bit
              if (parity = '1' and PARITY_MODE = 1) or (parity = '0' and PARITY_MODE = 0) then
                -- Add 0 as parity bit
                reg <= stop_bits_suffix & '0' & parallel_in & '0';
              else 
                -- Add 1 as parity bit
                reg <= stop_bits_suffix & '1' & parallel_in & '0';
              end if;
            else  
              -- Add no parity bit
              reg <= stop_bits_suffix & parallel_in & '0';
            end if;
            -- reset counter
            counter <= (others => '0');
            -- set buffer data saved output
            buffer_data_saved <= '1';
          else
            --no new data given
            -- Set counter to max value
            counter <= (others => '1');
          end if;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
