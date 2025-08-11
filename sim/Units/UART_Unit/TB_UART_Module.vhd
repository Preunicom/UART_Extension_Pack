library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_UART_Module is
  Port (
    signal tb_error : out std_logic
  );
end TB_UART_Module;

architecture TESTBENCH of TB_UART_Module is
  component TB_UARTUnit
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_Prescaler
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_Serializer
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_Buffer_Register_Serializer
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_Deserializer
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_Buffer_Register_Deserializer
    Port (
      tb_error : out std_logic
    );
  end component;
  signal tb_error_TB_UARTUnit : std_logic;
  signal tb_error_TB_Prescaler : std_logic;
  signal tb_error_TB_Serializer : std_logic;
  signal tb_error_TB_Buffer_Register_Serializer : std_logic;
  signal tb_error_TB_Deserializer : std_logic;
  signal tb_error_TB_Buffer_Register_Deserializer : std_logic;
begin
  UARTUnit: TB_UARTUnit port map(tb_error_TB_UARTUnit);
  Prescaler: TB_Prescaler port map(tb_error_TB_Prescaler);
  Serializer: TB_Serializer port map(tb_error_TB_Serializer);
  Buffer_Register_Serializer: TB_Buffer_Register_Serializer port map(tb_error_TB_Buffer_Register_Serializer);
  Deserializer: TB_Deserializer port map(tb_error_TB_Deserializer);
  Buffer_Register_Deserializer: TB_Buffer_Register_Deserializer port map(tb_error_TB_Buffer_Register_Deserializer);

  tb_error <= '0' when 
    (tb_error_TB_UARTUnit = '0')
    and (tb_error_TB_Prescaler = '0')
    and (tb_error_TB_Serializer = '0')
    and (tb_error_TB_Buffer_Register_Serializer = '0')
    and (tb_error_TB_Deserializer = '0')
    and (tb_error_TB_Buffer_Register_Deserializer = '0') else '1';
    
end TESTBENCH;
