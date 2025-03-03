library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity Buffer_Register_Deserializer is
  Generic(
    DATA_BITS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
    frame_error_in, parity_error_in : in std_logic;
    write_en : in std_logic;
    parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
    frame_error_out, parity_error_out : out std_logic;
    new_data : out std_logic
  );
end Buffer_Register_Deserializer;

architecture Behavioral of Buffer_Register_Deserializer is
  signal data : std_logic_vector(DATA_BITS-1 downto 0);
  signal frame_error_buf, parity_error_buf : std_logic;
begin

  BUFDES: process(clk, rst)
  begin
    if rst = '1' then
      data <= (others => '0');
      parallel_out <= (others => '0');
      frame_error_buf <= '0';
      parity_error_buf <= '0';
      frame_error_out <= '0';
      parity_error_out <= '0';
      new_data <= '0';
    elsif rising_edge(clk) then
      new_data <= '0';
      parallel_out <= data;
      frame_error_out <= frame_error_buf;
      parity_error_out <= parity_error_buf;
      if write_en = '1' then
        new_data <= '1';
        data <= parallel_in;
        parallel_out <= parallel_in;
        frame_error_buf <= frame_error_in;
        frame_error_out <= frame_error_in;
        parity_error_buf <= parity_error_in;
        parity_error_out <= parity_error_in;
      end if;
    end if;
  end process;

end Behavioral;