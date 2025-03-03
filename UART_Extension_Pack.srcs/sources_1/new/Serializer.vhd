library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Serializer is
  Generic(
    -- DATA_BITS + STOP_BITS <= 15 has to be fullfilled
    DATA_BITS : integer := 8;
    STOP_BITS : integer := 1;
    PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
    PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
  );
  Port ( 
    clk, rst, write_enable : in std_logic;
    parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
    serial_out : out std_logic;
    buffer_data_saved : out std_logic
  );
end Serializer;

architecture Behavioral of Serializer is
  signal reg : std_logic_vector(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto 0) := (others => '1'); -- data + stop + start + parity bits
  signal counter : std_logic_vector(3 downto 0) := (others => '0');
  signal stop_bits_suffix : std_logic_vector(STOP_BITS-1 downto 0) := (others => '1');
begin

  SER: process(clk, rst)
    variable parity : std_logic; -- 0: Even number of ones; 1: Odd number of ones
  begin
    if rst = '1' then
      parity := '0';
      reg <= (others => '1');
      counter <= (others => '0');
      serial_out <= '1';
      buffer_data_saved <= '1';
    elsif rising_edge(clk) then
      parity := '0';
      buffer_data_saved <= '0';
      counter <= counter + 1;
      serial_out <= reg(0);
      reg <= '1' & reg(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto 1);
      if counter = DATA_BITS+STOP_BITS+PARITY_ACTIVE then
        if write_enable = '1' then
          if PARITY_ACTIVE = 1 then
            -- Calculate parity
            for i in 0 to DATA_BITS-1 loop
              parity := parity xor parallel_in(i);
            end loop;
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
          counter <= (others => '0');
          buffer_data_saved <= '1';
        else
          counter <= "1001";
        end if;
      end if;
    end if;
  end process;

end Behavioral;
