--! @file
--! @brief SPI clock manager.
--! @details Controls SCK polarity/phase per SPI mode, generates serializer/deserializer clock enables, manages CS lines and prescaler reset, and indicates ready state.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

--! Entity coordinating SPI SCK generation, enable pulses, chip-select handling, and transaction control.
entity SPI_CLK_Manager is
  Generic (
    DATA_BITS : integer := 8; --! Number of data bits per SPI frame.
    SPI_MODE : integer := 0; --! SPI mode (0..3) defining CPOL/CPHA.
    AMOUNT_SLAVES : integer := 1 --! Number of chip-select lines (slaves).
  );
  Port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    write_en : in std_logic; --! Strobe to start a new SPI transaction.
    slave_id : in integer; --! Selected slave index (0..AMOUNT_SLAVES-1).
    prescaled_falling_edge : in std_logic; --! Falling-edge pulse from prescaler at target SPI rate.
    prescaled_rising_edge : in std_logic; --! Rising-edge pulse from prescaler at target SPI rate.
    prescaler_rst : out std_logic; --! Reset/stall signal for prescaler between transactions.
    deserializer_clk_en : out std_logic; --! Enable pulse for SPI deserializer.
    serializer_clk_en : out std_logic; --! Enable pulse for SPI serializer.
    SCK : out std_logic; --! SPI clock output.
    CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1'); --! Chip-select lines (active low).
    ready : out std_logic := '1' --! High when a new transaction can be accepted.
  );
end SPI_CLK_Manager;

--! Architecture implementing a small FSM to control CS, prescaler reset, and clock enables according to SPI mode.
architecture Behavioral of SPI_CLK_Manager is
  --! Counts data bits to determine transaction completion.
  signal counter : integer := 0;
  --! One-cycle pulse to align first serializer enable with CS assertion.
  signal virtual_CS_clk_edge : std_logic;
  --! Latched slave index used during the active transaction.
  signal slave_id_CS_intern : integer;
  --! Registered next value of SCK (one-cycle delayed output).
  signal SCK_next : std_logic;

  --! FSM states
  type statetype is (IDLE, START_TRANS, SEND);
  --! Current FSM state.
  signal state : statetype := IDLE;
begin

  --! State machine: handles transaction start, CS control, bit counting, and prescaler reset.
  STATE_CHART: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= IDLE;
        CS <= (others => '1');
        prescaler_rst <= '1';
        virtual_CS_clk_edge <= '0';
        counter <= 0;
        slave_id_CS_intern <= 0;
        ready <= '1';
      else
        prescaler_rst <= '0';
        ready <= '0';
        state <= IDLE;
        virtual_CS_clk_edge <= '0';
        case state is
          when IDLE =>
            -- Waiting for new data
            prescaler_rst <= '1';
            CS <= (others => '1');
            ready <= '1';
            if write_en = '1' then
              -- New data found --> send additional edge if recogniced new data
              virtual_CS_clk_edge <= '1';
              prescaler_rst <= '0';
              slave_id_CS_intern <= slave_id;
              ready <= '0';
              state <= START_TRANS;
            end if;
          when START_TRANS =>
            -- Start transmission
            prescaler_rst <= '0';
            CS(slave_id_CS_intern) <= '0';
            state <= SEND;
            counter <= 0; -- Needed to change state after transmission
          when SEND=>
            -- Sending data
            state <= SEND;
            if ((prescaled_rising_edge = '1' and (SPI_MODE = 2 or SPI_MODE = 3)) or (prescaled_falling_edge = '1' and (SPI_MODE = 0 or SPI_MODE = 1))) then
              -- recogniced SPI Mode matching last edge type edge
              counter <= counter + 1;
            end if;
            if counter = DATA_BITS then
              -- last bit sent
              prescaler_rst <= '1';
              ready <= '1';
              state <= IDLE;
            end if;
        end case;
      end if;
    end if;  
  end process;

  --! Generates serializer/deserializer enable pulses based on SPI mode and prescaled edges.
  CREATE_CLK_EN: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        serializer_clk_en <= '0';
        deserializer_clk_en <= '0';
      else
        if SPI_MODE = 0 then
          serializer_clk_en <= prescaled_falling_edge or virtual_CS_clk_edge;
          deserializer_clk_en <= prescaled_rising_edge;
        elsif SPI_MODE = 1 then
          serializer_clk_en <= prescaled_rising_edge;
          deserializer_clk_en <= prescaled_falling_edge;
        elsif SPI_MODE = 2 then
          serializer_clk_en <= prescaled_rising_edge or virtual_CS_clk_edge;
          deserializer_clk_en <= prescaled_falling_edge;
        else -- SPI Mode 3
          serializer_clk_en <= prescaled_falling_edge;
          deserializer_clk_en <= prescaled_rising_edge;
        end if;
      end if;
    end if;
  end process;

  --! Produces SCK with correct idle level per SPI mode and one-cycle output delay.
  CREATE_CLK: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        if SPI_MODE = 0 or SPI_MODE = 1 then
          SCK <= '0';
          SCK_next <= '0';
        else
          SCK <= '1';
          SCK_next <= '1';
        end if;
      else
        if prescaled_rising_edge = '1' then
          SCK_next <= '1';
        elsif prescaled_falling_edge = '1' then
          SCK_next <= '0';
        end if;
        SCK <= SCK_next; -- one clock cycle delay to give (de-)serializer time to react on the clk enable signal
      end if;
    end if;
  end process;

end Behavioral;