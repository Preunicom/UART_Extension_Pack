library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Buffer_Register_Serializer is
  Generic(
    DATA_BITS : integer := 8
  );
  Port ( 
    clk, rst, write_enable : in std_logic;
    data_in : in std_logic_vector(DATA_BITS-1 downto 0);
    data_not_needed_anymore : in std_logic;
    data_out : out std_logic_vector(DATA_BITS-1 downto 0);
    full : out std_logic
    );
end Buffer_Register_Serializer;

architecture Behavioral of Buffer_Register_Serializer is
  signal data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '1');
  signal full_int : std_logic := '0';
  signal last_serializer_ready_status : std_logic := '1';
  signal serializer_ready_status_change_detected : std_logic := '1';
begin
  
  BUFS: process(clk, rst)
  begin
    if rst = '1' then
      data <= (others => '1');
      data_out <= (others => '1');
      full <= '0';
      full_int <= '0';
      last_serializer_ready_status <= '1';
      serializer_ready_status_change_detected <= '1';
    elsif rising_edge(clk) then
      serializer_ready_status_change_detected <= serializer_ready_status_change_detected;
      last_serializer_ready_status <= data_not_needed_anymore;
      data_out <= data;
      data <= data;
      -- Default case:
      -- current data not sent
      --> Wait for current data sent
      full <= full_int;
      full_int <= full_int;

      if (data_not_needed_anymore = '1' and last_serializer_ready_status = '0') or serializer_ready_status_change_detected = '1' then
        serializer_ready_status_change_detected <= '1';
        -- current data sent
        --> Get new data
        full <= '0'; --> automatically sets write enable to false at shift reg
        full_int <= '0';
        if write_enable = '1' then
          -- new data available to load
          --> Get data if current data sent
          data <= data_in;
          data_out <= data_in;
          full_int <= '1';
          full <= '1';
          serializer_ready_status_change_detected <= '0';
        end if; 
      end if;
    end if;
  end process;

end Behavioral;
