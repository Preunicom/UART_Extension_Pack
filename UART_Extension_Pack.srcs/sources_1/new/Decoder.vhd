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
    uart_error : in std_logic;
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
  signal uart_error_synced : std_logic;
  signal uart_error_S1 : std_logic;
  signal uart_error_combined : std_logic := '0';
begin

  SYNC_IO: process(clk, rst)
  begin
    if rst = '1' then
      out_en <= '0';
      access_mode <= (others => '0');
      unit_number <= (others => '0');
      unit_data <= (others => '0');
    elsif rising_edge(clk) then
      -- Set last_uart_inp_valid to synced current one
      last_uart_inp_valid <= uart_inp_valid_synced;
      -- Sync in
      uart_inp_synced <= uart_inp;
      uart_inp_valid_synced <= uart_inp_valid;
      uart_error_synced <= uart_error;
      -- Sync out
      case state is
        when S0 => -- waiting for data
          out_en <= '0';
          -- resets uart errors of others states
          uart_error_S1 <= '0';
          uart_error_combined <= '0';
        when S1 => -- Get first data part
          out_en <= '0';
          uart_error_S1 <= uart_error_S1 or uart_error_synced;
          -- resets uart errors of other states
          uart_error_combined <= '0';
        when S2 => -- Get second data part
          -- set decoded data pair data to outputs
          access_mode <= unit_number_data(4 downto 3);
          unit_number <= unit_number_data(2 downto 0);
          unit_data <= uart_inp_synced;
          -- resets uart errors of other states
          uart_error_S1 <= '0';
          -- Sets uart_error_combined to one if error was present while receiving one of the 2 packages
          uart_error_combined <= uart_error_synced or uart_error_combined or uart_error_S1; 
          -- Enable output if no UART error exists
          out_en <= not (uart_error_synced or uart_error_combined or uart_error_S1);
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

  ASYNC: process(state, uart_inp_synced, unit_number_data, counter_ready, uart_inp_valid_synced, last_uart_inp_valid)
  begin
    nextstate <= S0;
    unit_number_data <= unit_number_data;
    case state is
      when S0 => 
        -- no input to decode given
        if uart_inp_valid_synced = '1' and last_uart_inp_valid = '0' then
          -- edge detected of uart_inp_valid_synced
          --> New data (first half)
          nextstate <= S1;
          counter_rst <= '1';
          unit_number_data <= uart_inp_synced;
        end if;
      when S1 =>
        -- get first half of the data
        counter_rst <= '0';
        if uart_inp_valid_synced = '1' and last_uart_inp_valid = '0' then
          -- edge detected of uart_inp_valid_synced
          --> New data (second half)
          nextstate <= S2;
          counter_rst <= '1';
        else
          nextstate <= S1;
        end if;
        if counter_ready = '1' then
          -- resets after 1ms if no new data is available during this time
          nextstate <= S0;
        end if;
      when S2 =>
        -- get second half of the data
        counter_rst <= '0';
        nextstate <= S2;
        if uart_inp_valid_synced = '1' and last_uart_inp_valid = '0' then
          -- edge detected of uart_inp_valid_synced
          --> New data (next pair of data)
          nextstate <= S1;
          counter_rst <= '1';
          unit_number_data <= uart_inp_synced;
        elsif counter_ready = '1' then
          -- resets after 1ms if no new data is available during this time
          nextstate <= S0;
        end if;
      when others => null;
    end case;
  end process;

  TIMER: process(clk, counter_rst)
    -- timer for 1 ms
  begin
    if counter_rst = '1' then
      counter <= 0;
    elsif rising_edge(clk) then
      counter_ready <= '0';
      counter <= counter + 1;
      if counter = (IN_FREQ_HZ / 1000) - 1 then
        -- timer ends
        counter <= 0;
        counter_ready <= '1';
      end if;
    end if;
  end process;
  
end Behavioral;