library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
  Generic (
    DATA_BITS : integer := 8;
    IN_FREQ_HZ : integer := 12000000
  );
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    uart_inp : in std_logic_vector(DATA_BITS-1 downto 0);
    uart_inp_valid : in std_logic;
    out_en : out std_logic;
    access_mode : out std_logic_vector(1 downto 0);
    unit_number : out std_logic_vector(2 downto 0); 
    unit_data : out std_logic_vector(DATA_BITS-1 downto 0)
  );
end Decoder;

architecture Behavioral of Decoder is
  type statetype is (S0, S1, S2);
  signal state : statetype := S0;
  signal nextstate : statetype;
  signal unit_number_data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
  signal counter: integer := 0;
  signal counter_rst : std_logic := '1';
  signal counter_ready : std_logic := '0';

  signal uart_inp_synced : std_logic_vector(DATA_BITS-1 downto 0);
  signal uart_inp_valid_synced : std_logic;
  signal last_uart_inp_valid : std_logic := '0';
begin

  SYNC_IO: process(clk, rst)
  begin
    if rst = '1' then
      out_en <= '0';
      access_mode <= (others => '0');
      unit_number <= (others => '0');
      unit_data <= (others => '0');
    elsif rising_edge(clk) then
      -- Set last
      last_uart_inp_valid <= uart_inp_valid_synced;
      -- Sync in
      uart_inp_synced <= uart_inp;
      uart_inp_valid_synced <= uart_inp_valid;
      -- Sync out
      case state is
        when S2 =>
          access_mode <= unit_number_data(4 downto 3);
          unit_number <= unit_number_data(2 downto 0);
          unit_data <= uart_inp_synced;
          if nextstate = S2 then
            out_en <= '1';
          else
            out_en <= '0';
          end if;
        when others =>
          out_en <= '0';
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

  ASYNC: process(state, uart_inp_synced, unit_number_data, counter_ready, uart_inp_valid_synced, last_uart_inp_valid)
  begin
    nextstate <= S0;
    unit_number_data <= unit_number_data;
    case state is
      when S0 => 
        if uart_inp_valid_synced = '1' and last_uart_inp_valid = '0' then
          nextstate <= S1;
          counter_rst <= '1';
          unit_number_data <= uart_inp_synced;
        end if;
      when S1 =>
        nextstate <= S1;
        counter_rst <= '0';
        if uart_inp_valid_synced = '1' and last_uart_inp_valid = '0' then
          nextstate <= S2;
          counter_rst <= '1';
        else
          nextstate <= S1;
        end if;
        if counter_ready = '1' then
          nextstate <= S0;
        end if;
      when S2 =>
        counter_rst <= '0';
        nextstate <= S2;
        if uart_inp_valid_synced = '1' and last_uart_inp_valid = '0' then
          nextstate <= S1;
          counter_rst <= '1';
          unit_number_data <= uart_inp_synced;
        elsif counter_ready = '1' then
          nextstate <= S0;
        end if;
      when others => null;
    end case;
  end process;

  TIMER: process(clk, counter_rst)
  begin
    if counter_rst = '1' then
      counter <= 0;
    elsif rising_edge(clk) then
      counter_ready <= '0';
      counter <= counter + 1;
      if counter = (IN_FREQ_HZ / 1000) - 1 then
        counter <= 0;
        counter_ready <= '1';
      end if;
    end if;
  end process;
  
end Behavioral;