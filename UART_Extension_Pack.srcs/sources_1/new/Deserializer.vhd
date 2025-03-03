library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity Deserializer is
  Generic(
    -- DATA_BITS + STOP_BITS <= 15 has to be fullfilled
    DATA_BITS : integer := 8;
    STOP_BITS : integer := 1;
    PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
    PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
  );
  Port ( 
    clk, rst : in std_logic;
    serial_in : in std_logic;
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
    frame_error, parity_error : out std_logic;
    data_valid : out std_logic
  );
end Deserializer;

architecture Behavioral of Deserializer is
  signal reg : std_logic_vector(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto 0);
  signal counter : std_logic_vector(3 downto 0) := "0000";
  signal stop_bits_suffix : std_logic_vector(STOP_BITS-1 downto 0) := (others => '1');
begin

  DESER: process(clk, rst)
    variable parity : std_logic;
  begin
    if rst = '1' then
      parity := '0';
      reg <= (others => '0');
      counter <= (others => '0');
      parallel_out <= (others => '0');
      data_valid <= '0';
      frame_error <= '0';
      parity_error <= '0';
    elsif rising_edge(clk) then
      parity := '0';
      parallel_out <= (others => '0');
      data_valid <= '0';
      frame_error <= '0';
      parity_error <= '0';
      counter <= counter + 1;
      reg <= serial_in & reg(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto 1);
      if counter = 0 then
        if serial_in = '1' then
            counter <= (others => '0');
        end if;
      end if;
      if counter = DATA_BITS+STOP_BITS+PARITY_ACTIVE then
        parallel_out <= reg(DATA_BITS+1 downto 2); -- Last Bit not shifted yet (this clock cyle shift) and start bit as offset 
        data_valid <= '1';
        if (reg(DATA_BITS+STOP_BITS+PARITY_ACTIVE downto DATA_BITS+STOP_BITS+PARITY_ACTIVE-STOP_BITS+1) & serial_in) = stop_bits_suffix then
            frame_error <= '0';
        else
            frame_error <= '1';
        end if;
        if PARITY_ACTIVE = 1 then
            -- Calculate parity incl. parity bit
            for i in 2 to DATA_BITS+2 loop
              parity := parity xor reg(i);
            end loop;
            if (parity = '1' and PARITY_MODE = 1) or (parity = '0' and PARITY_MODE = 0) then
              -- parity ok
              parity_error <= '0';
            else 
              -- parity not ok
              parity_error <= '1';
            end if;
          else  
            -- no parity
            parity_error <= '0';
          end if;
        counter <= (others => '0');
      end if;
    end if;
  end process;


end Behavioral;
