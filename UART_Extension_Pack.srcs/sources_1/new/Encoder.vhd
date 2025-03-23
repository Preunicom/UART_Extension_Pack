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
  type statetype is (S0, S1, S2);
  signal state : statetype := S0;
  signal zero_prefix_unit_number : std_logic_vector(DATA_BITS-1 downto 6) := (others => '0');
  signal unit_number_reg : std_logic_vector(5 downto 0);
  signal unit_data_reg : std_logic_vector(DATA_BITS-1 downto 0);
  -- edges
  signal last_write_en : std_logic := '0';
  signal last_uart_is_empty : std_logic := '0';
begin

  PROC1: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Clear intern data
        state <= S0;
        unit_number_reg <= (others =>'0');
        unit_data_reg <= (others =>'0');
        -- Cleart ouptuts
        uart_out_valid <= '0';
        uart_out <= (others => '0');
        schedule_next <= '1';
      else
        uart_out_valid <= '0';
        schedule_next <= '0';
        case state is 
          when S0 => -- Waiting for data from scheduler and units
            if last_write_en = '0' and write_en = '1' then
              -- new data given
              --> Wait for UART ready
              state <= S1;
              -- Save input values
              unit_number_reg <= unit_number;
              unit_data_reg <= unit_data;
            else
              -- Wait for new data
              state <= S0;
              schedule_next <= '1';
            end if;
          when S1 => -- Waiting for UART unit to be ready for new data to send unit number
            if uart_is_empty = '1' then
              -- UART unit ready
              --> Send zero extended unit number
              uart_out_valid <= '1';
              uart_out <= zero_prefix_unit_number & unit_number_reg;
              state <= S2;
            else
              -- Wait for UART unit ready
              state <= S1;
            end if;
          when S2 => -- Waiting for UART unit to be ready for new data to send unit data
            if last_uart_is_empty = '0' and uart_is_empty = '1' then
              -- UART unit ready
              --> Send unit data
              uart_out_valid <= '1';
              uart_out <= unit_data_reg;
              -- Get next data to schedule
              schedule_next <= '1';
              state <= S0;
            else
              -- Wait for UART unit ready
              state <= S2;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_en <= '0';
        last_uart_is_empty <= '0';
      else
        -- Set last_uart_inp_valid to synced current one
        last_write_en <= write_en;
        last_uart_is_empty <= uart_is_empty;
      end if;
    end if;
  end process;
  
end Behavioral;