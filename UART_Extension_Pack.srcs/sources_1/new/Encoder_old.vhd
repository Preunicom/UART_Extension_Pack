library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Encoder is
  Generic (
    DATA_BITS : integer := 8
  );
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    write_en : in std_logic;
    uart_is_empty : in std_logic;
    unit_number : in std_logic_vector(5 downto 0);
    unit_data : in std_logic_vector(DATA_BITS-1 downto 0);
    uart_out : out std_logic_vector(DATA_BITS-1 downto 0);
    uart_out_valid : out std_logic;
    schedule_next : out std_logic
  );
end Encoder;

architecture Behavioral of Encoder is
  type statetype is (S0, S1, S2, S3, S4, S5);
  signal state : statetype := S0;
  signal nextstate : statetype;
  signal zero_prefix_unit_number : std_logic_vector(DATA_BITS-1 downto 6) := (others => '0');
begin

  SYNC: process(clk, rst)
  begin
    if rst = '1' then
      state <= S0;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  ASYNC: process(state, write_en, uart_is_empty)
  begin
    nextstate <= S0;
    schedule_next <= '0';
    case state is
      when S0 =>
        -- waiting for data
        uart_out_valid <= '0';
        uart_out <= (others => '0');
        schedule_next <= '1';
        if write_en = '1' then
          -- got new data
          schedule_next <= '0';
          nextstate <= S1;
        end if;
      when S1 =>
        -- waiting for uart slot
        uart_out_valid <= '0';
        uart_out <= zero_prefix_unit_number & unit_number;
        nextstate <= S1;
        if uart_is_empty = '1' then
          -- slot free
          nextstate <= S2;
        end if;
      when S2 =>
        -- uart slot free and giving data to uart in progress
        uart_out_valid <= '1';
        uart_out <= zero_prefix_unit_number & unit_number;
        nextstate <= S2;
        if uart_is_empty = '0' then
          -- slot taken
          nextstate <= S3;
        end if;
      when S3 =>
        -- waiting for uart slot
        uart_out_valid <= '0';
        uart_out <= unit_data;
        nextstate <= S3;
        if uart_is_empty = '1' then
          -- slot free
          nextstate <= S4;
        end if;
      when S4 => 
        -- uart slot free and giving data to uart in progress
        uart_out_valid <= '1';
        uart_out <= unit_data; 
        nextstate <= S4;
        if uart_is_empty = '0' then
          -- slot taken
          schedule_next <= '1';
          nextstate <= S5;
        end if;
      when S5 =>
        -- one clock cyle delay to meet scheduler timing for scheduling next data
        uart_out_valid <= '0';
        uart_out <= (others => '0');
        schedule_next <= '1';
        nextstate <= S0;
    end case;
  end process;
  
end Behavioral;