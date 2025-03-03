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
    unit_number : in std_logic_vector(2 downto 0); 
    unit_data : in std_logic_vector(DATA_BITS-1 downto 0);
    uart_out : out std_logic_vector(DATA_BITS-1 downto 0);
    uart_out_valid : out std_logic
  );
end Encoder;

architecture Behavioral of Encoder is
  type statetype is (S0, S1, S2, S3, S4);
  signal state : statetype := S0;
  signal nextstate : statetype;
  signal zero_prefix_unit_number : std_logic_vector(DATA_BITS-1 downto 3) := (others => '0');
  signal write_en_synced : std_logic;
  signal unit_number_synced : std_logic_vector(2 downto 0); 
  signal uart_is_empty_synced : std_logic;
  signal unit_data_synced : std_logic_vector(DATA_BITS-1 downto 0);
begin

  SYNC_IO: process(clk, rst)
  begin
    if rst = '1' then
      uart_out <= (others => '0');
      uart_out_valid <= '0';
    elsif rising_edge(clk) then
      -- Sync in
      write_en_synced <= write_en;
      unit_number_synced <= unit_number;
      unit_data_synced <= unit_data;
      uart_is_empty_synced <= uart_is_empty;
      -- Sync out
      case state is 
        when S0 =>
          uart_out_valid <= '0';
          uart_out <= (others => '0');
        when S1 =>
          uart_out_valid <= '1';
          uart_out <= zero_prefix_unit_number & unit_number_synced;
        when S2 => 
          uart_out_valid <= '0';
          uart_out <= zero_prefix_unit_number & unit_number_synced;
        when S3 => 
          uart_out <= unit_data_synced;
          uart_out_valid <= '1';
        when S4 => 
          uart_out <= unit_data_synced;
          uart_out_valid <= '0';
        when others => null;
      end case;
    end if;
  end process;

  SYNC: process(clk, rst)
  begin
    if rst = '1' then
      state <= S0;
    elsif rising_edge(clk) then
      state <= nextstate;
    end if;
  end process;

  ASYNC: process(state, write_en_synced, uart_is_empty_synced)
  begin
    nextstate <= S0;
    case state is
      when S0 =>
        if write_en_synced = '1' then
          nextstate <= S1;
        end if;
      when S1 =>
        nextstate <= S2;
      when S2 =>
        nextstate <= S2;
        if uart_is_empty_synced = '1' then
          nextstate <= S3;
        end if;
      when S3 =>
        nextstate <= S4;
      when S4 => 
        nextstate <= S4;
        if uart_is_empty_synced = '1' then
          nextstate <= S0;
        end if;
    end case;
  end process;
  
end Behavioral;