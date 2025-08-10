--! @file
--! @brief UART packet encoder for unit control.
--! @details Sends a two-byte packet: first the zero-extended unit number, then the unit data. Coordinates with UART readiness and requests the next schedule item when done.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--! Encodes control information into UART bytes and triggers scheduling of the next unit.
entity Encoder is
  Generic (
    DATA_BITS : integer := 8 --! The amount of data bits used by the ExtPack and the host.
  );
  Port ( 
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Enable signal for the data input.
    uart_is_empty : in std_logic; --! Indicates UART TX is ready to accept a new UART package.
    unit_number : in std_logic_vector(5 downto 0); --! Target unit number (0...63).
    unit_data : in std_logic_vector(DATA_BITS-1 downto 0); --! Payload data package to send as second packet byte.
    uart_out : out std_logic_vector(DATA_BITS-1 downto 0); --! UART TX data.
    uart_out_valid : out std_logic; --! Enable signal for the uart_out signal.
    schedule_next : out std_logic --! Request to fetch/schedule next unit after data has been sent.
  );
end Encoder;

--! Architecture implementing a three-state encoder to send unit number and data over UART.
architecture Behavioral of Encoder is
  --! State machine states for the encoder state machine.
  type statetype is (IDLE, SEND_UNIT_NUM, SEND_UNIT_DATA);
  --! Current state of the encoder state machine.
  signal state : statetype := IDLE;
  --! Zero extension vector used to widen the 6-bit unit number to DATA_BITS.
  signal zero_prefix_unit_number : std_logic_vector(DATA_BITS-1 downto 6) := (others => '0');
  --! Latched copy of the unit number.
  signal unit_number_reg : std_logic_vector(5 downto 0);
  --! Latched copy of the unit data.
  signal unit_data_reg : std_logic_vector(DATA_BITS-1 downto 0);
  --! Previous value of write_en for rising-edge detection.
  signal last_write_en : std_logic := '0';
  --! Previous value of uart_is_empty for edge detection between bytes.
  signal last_uart_is_empty : std_logic := '0';
begin

  --! Main encoder process: latches inputs, sends unit number and data when UART is ready, and requests next schedule item.
  SEND_STATE_MACHINE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Clear internal registers.
        state <= IDLE;
        unit_number_reg <= (others =>'0');
        unit_data_reg <= (others =>'0');
        -- Clear outputs.
        uart_out_valid <= '0';
        uart_out <= (others => '0');
        schedule_next <= '1';
      else
        uart_out_valid <= '0';
        schedule_next <= '0';
        case state is 
          when IDLE => -- Waiting for data from scheduler and units.
            if last_write_en = '0' and write_en = '1' then
              -- New data available.
              -- Wait for UART ready.
              state <= SEND_UNIT_NUM;
              -- Latch input values.
              unit_number_reg <= unit_number;
              unit_data_reg <= unit_data;
            else
              -- Wait for new data.
              state <= IDLE;
              schedule_next <= '1';
            end if;
          when SEND_UNIT_NUM => -- Waiting for UART TX to be ready to send the unit number.
            if uart_is_empty = '1' then
              -- UART TX ready.
              -- Send zero-extended unit number.
              uart_out_valid <= '1';
              uart_out <= zero_prefix_unit_number & unit_number_reg;
              state <= SEND_UNIT_DATA;
            else
              -- Wait for UART ready.
              state <= SEND_UNIT_NUM;
            end if;
          when SEND_UNIT_DATA => -- Waiting for UART TX to be ready to send the unit data.
            if last_uart_is_empty = '0' and uart_is_empty = '1' then
              -- UART TX ready.
              -- Send unit data.
              uart_out_valid <= '1';
              uart_out <= unit_data_reg;
              -- Request next data to schedule.
              schedule_next <= '1';
              state <= IDLE;
            else
              -- Wait for UART ready.
              state <= SEND_UNIT_DATA;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  --! Edge detection process: captures previous values for write_en and uart_is_empty.
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_en <= '0';
        last_uart_is_empty <= '0';
      else
        -- Update edge-detection registers with current inputs.
        last_write_en <= write_en;
        last_uart_is_empty <= uart_is_empty;
      end if;
    end if;
  end process;
  
end Behavioral;