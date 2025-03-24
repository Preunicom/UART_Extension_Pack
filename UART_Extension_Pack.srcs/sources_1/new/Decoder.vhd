library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Decoder is
  Generic (
    DATA_BITS : integer := 8;
    FPGA_FREQ : integer := 12000000;
    HOST_BAUD : integer := 1000000
  );
  Port ( 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    uart_inp : in std_logic_vector(DATA_BITS-1 downto 0);
    uart_inp_valid : in std_logic;
    uart_error : in std_logic;
    out_en : out std_logic;
    access_mode : out std_logic_vector(1 downto 0);
    unit_number : out std_logic_vector(5 downto 0); 
    unit_data : out std_logic_vector(DATA_BITS-1 downto 0)
  );
end Decoder;

architecture Behavioral of Decoder is
  -- state signals
  type statetype is (S0, S1);
  signal state : statetype := S0;
  -- counter signals
  signal counter: integer := 0;
  signal counter_rst : std_logic := '1';
  signal counter_ready : std_logic := '0';
  -- data signals
  signal uart_error_S1 : std_logic := '0';
  signal last_uart_inp_valid : std_logic := '0';
  signal unit_number_data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
begin

  PROC1: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= S0;
        out_en <= '0';
        access_mode <= (others => '0');
        unit_number <= (others => '0');
        unit_data <= (others => '0');
        uart_error_S1 <= '0';
        unit_number_data <= (others => '0');
      else 
        -- Set default values
        out_en <= '0';
        counter_rst <= '0';
        case state is 
          when S0 => -- no data received, waiting for unit number and access mode
            if last_uart_inp_valid = '0' and uart_inp_valid = '1' then
              -- edge detected of uart_inp_valid_synced
              --> New data (first half --> unit number and access mode)
              state <= S1;
              counter_rst <= '1';
              uart_error_S1 <= uart_error;
              unit_number_data <= uart_inp;
            else 
              -- Waiting for unit number
              state <= S0;
            end if;
          when S1 => -- unit number already received, waiting for unit data
            if last_uart_inp_valid = '0' and uart_inp_valid = '1' then
              -- edge detected of uart_inp_valid_synced
              --> New data (second half --> unit data)
              state <= S0;
              -- enable output if no uart error exists and set output data
              out_en <= not (uart_error_S1 or uart_error);
              access_mode <= unit_number_data(7 downto 6);
              unit_number <= unit_number_data(5 downto 0);
              unit_data <= uart_inp;
            elsif counter_ready = '1' then
              -- no data received for too long
              --> Waiting for next unit number as we missed the data
              state <= S0;
            else
              -- Waiting for unit data or timer ready
              state <= S1;
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
        last_uart_inp_valid <= '0';
      else
        -- Set last_uart_inp_valid to synced current one
        last_uart_inp_valid <= uart_inp_valid;
      end if;
    end if;
  end process;

  TIMER: process(clk)
    -- timer for duration of ca. 3 UART package transmissions
  begin
    if rising_edge(clk) then
      if counter_rst = '1' then
        counter <= 0;
      else
        counter_ready <= '0';
        counter <= counter + 1;
        if counter >= (((3*(DATA_BITS+3))*FPGA_FREQ)/HOST_BAUD) - 1 then
          -- timer ends
          counter <= 0;
          counter_ready <= '1';
        end if;
      end if;
    end if;
  end process;
  
end Behavioral;