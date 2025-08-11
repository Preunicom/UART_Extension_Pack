--! @file
--! @brief Incoming UART packet decoder for unit control.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Decodes a two-part UART packet into control fields and data, handling errors and timeouts.
entity Decoder is
  Generic (
    DATA_BITS : integer := 8; --! The amount of data bits used by the ExtPack and the host.
    FPGA_FREQ : integer := 12000000; --! The frequency in Hz of the FPGA.
    HOST_BAUD : integer := 1000000 --! The BAUD rate used by the host.
  );
  Port ( 
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    uart_inp : in std_logic_vector(DATA_BITS-1 downto 0); --! Parallel UART package input.
    uart_inp_valid : in std_logic; --! Enable signal for the uart_inp signal.
    uart_error : in std_logic; --! UART error indicator for the current UART package.
    out_en : out std_logic; --! Output enable signal when valid decoded data is ready.
    recv_error : out std_logic; --! Indicates that an error occurred during reception.
    access_mode : out std_logic_vector(1 downto 0); --! Access mode extracted from the first received UART package.
    unit_number : out std_logic_vector(5 downto 0); --! Unit number extracted from the first received UART package.
    unit_data : out std_logic_vector(DATA_BITS-1 downto 0) --! Unit data from the second received UART package.
  );
end Decoder;

--! Architecture implementing a state machine to process UART packets, detect errors, and handle timeouts.
architecture Behavioral of Decoder is
  --! Decoding machine chart state data type
  type statetype is (S0, S1);
  --! Current state of the packet decoding state machine.
  signal state : statetype := S0;
  --! Counts clock cycles for the inter-package timeout period.
  signal counter: integer := 0;
  --! Resets the counter when starting a new command.
  signal counter_rst : std_logic := '1';
  --! Indicates when the timeout counter has expired.
  signal counter_ready : std_logic := '0';
  --! Stores UART error flag from the first byte.
  signal uart_error_S1 : std_logic := '0';
  --! Previous value of uart_inp_valid for edge detection.
  signal last_uart_inp_valid : std_logic := '0';
  --! Stores the first package containing unit number and access mode.
  signal unit_number_data : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
begin

  --! Main decoding state machine process.
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
        recv_error <= '0';
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
              recv_error <= (uart_error_S1 or uart_error);
              access_mode <= unit_number_data(7 downto 6);
              unit_number <= unit_number_data(5 downto 0);
              unit_data <= uart_inp;
            elsif counter_ready = '1' then
              -- no data received for too long
              --> Waiting for next unit number as we missed the data
              recv_error <= '1';
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

  --! Captures previous uart_inp_valid to detect rising edges.
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

  --! Timeout timer process for detecting missing second byte within ~3 UART packet times.
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