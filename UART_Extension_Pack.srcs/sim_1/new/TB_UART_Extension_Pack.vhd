library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_UART_Extension_Pack is
end TB_UART_Extension_Pack;

architecture TESTBENCH of TB_UART_Extension_Pack is
  component TB_Main_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Decoder
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_PriorityScheduler
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Encoder
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_UART_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_GPIO_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Timer_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  signal tb_error : std_logic;
  signal tb_error_TB_Main_Unit : std_logic;
  signal tb_error_TB_Decoder : std_logic;
  signal tb_error_TB_PriorityScheduler : std_logic;
  signal tb_error_TB_Encoder : std_logic;
  signal tb_error_TB_UART_Wrapper : std_logic;
  signal tb_error_TB_GPIO_Wrapper : std_logic;
  signal tb_error_TB_Timer_Wrapper : std_logic;
begin
  Main_Unit: TB_Main_Unit port map(tb_error_TB_Main_Unit);
  Decoder: TB_Decoder port map(tb_error_TB_Decoder);
  PriorityScheduler: TB_PriorityScheduler port map(tb_error_TB_PriorityScheduler);
  Encoder: TB_Encoder port map(tb_error_TB_Encoder);
  UART_Wrapper: TB_UART_Wrapper port map(tb_error_TB_UART_Wrapper);
  GPIO_Wrapper: TB_GPIO_Wrapper port map(tb_error_TB_GPIO_Wrapper);
  Timer_Wrapper: TB_Timer_Wrapper port map(tb_error_TB_Timer_Wrapper);

  tb_error <= '0' when 
    (tb_error_TB_Main_Unit = '0')
    and (tb_error_TB_Decoder = '0')
    and (tb_error_TB_PriorityScheduler = '0')
    and (tb_error_TB_Encoder = '0')
    and (tb_error_TB_UART_Wrapper = '0')
    and (tb_error_TB_GPIO_Wrapper = '0')
    and (tb_error_TB_Timer_Wrapper = '0') else '1';

end TESTBENCH;
