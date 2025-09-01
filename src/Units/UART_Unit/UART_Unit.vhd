--! @file
--! @brief UART unit integrating transmitter and receiver.
--! @details Provides both TX and RX logic with configurable baud rate, data bits, stop bits, and parity settings.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! \defgroup UNIT ExtPack units
--! @brief Standard units of ExtPack.
--! @{

--! @brief Top-level UART entity instantiating UART_Transmitter and UART_Receiver.
--! @details UART_Module with transmitter und receiver.\n
--! Supports:\n
--! - BAUD rates less or equal to the input clock frequency\n
--! - 5-9 data bits\n
--! - parity (even/odd/no)\n
--! - 1 or 2 stop bits\n

entity UART_Unit is
--! @}
  Generic (
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz.
    BAUD_FREQ_HZ : integer := 9600; --! UART baud rate in Hz.
    DATA_BITS : integer := 8; --! Number of data bits per frame. @note Condition:  DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    STOP_BITS : integer := 1; --! Number of stop bits. @note Condition:  DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_ACTIVE : integer := 0; --! 0: No parity; 1: Parity enabled (even/odd per PARITY_MODE). @note Condition:  DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15
    PARITY_MODE : integer := 0 --! 0: Even parity; 1: Odd parity.
  );
  Port ( 
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    send_data : in std_logic_vector(DATA_BITS-1 downto 0); --! TX payload.
    write_en : in std_logic; --! TX write strobe.
    full : out std_logic; --! TX not ready / buffer full.
    TX_pin : out std_logic; --! UART transmitter pin.

    received_data : out std_logic_vector(DATA_BITS-1 downto 0); --! RX payload.
    frame_error : out std_logic; --! RX framing error.
    parity_error : out std_logic; --! RX parity error.
    new_data_received : out std_logic; --! Pulse: new RX data available.
    RX_pin : in std_logic --! UART receiver pin.
  );
end UART_Unit;

--! Architecture instantiating UART transmitter and receiver components.
architecture Behavioral of UART_Unit is
  --! Component declaration for UART_Transmitter.
  component UART_Transmitter
    Generic (
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0;
      PARITY_MODE : integer := 0
    );
    Port ( 
      clk, rst : in std_logic;
      data_in : in std_logic_vector(DATA_BITS-1 downto 0);
      write_en : in std_logic;
      full : out std_logic;
      serial_out : out std_logic
    );
  end component;
  --! Component declaration for UART_Receiver.
  component UART_Receiver
    Generic(
      IN_FREQ_HZ : integer := 12000000;
      BAUD_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0;
      PARITY_MODE : integer := 0
    );
    Port ( 
      clk, rst : in std_logic;
      serial_in : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error, parity_error : out std_logic;
      new_data : out std_logic
    );
  end component;
begin
  --! UART transmitter instance.
  TRANSMITTER: UART_Transmitter generic map(IN_FREQ_HZ, BAUD_FREQ_HZ, DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, rst, send_data, write_en, full, TX_pin);
  --! UART receiver instance.
  RECEIVER: UART_Receiver generic map(IN_FREQ_HZ, BAUD_FREQ_HZ, DATA_BITS, STOP_BITS, PARITY_ACTIVE, PARITY_MODE) port map(clk, rst, RX_pin, received_data, frame_error, parity_error, new_data_received);
  
end Behavioral;
