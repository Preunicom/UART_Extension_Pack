--! @file
--! @brief Top level testbench combining all tb_error signals of all testbenches to show an overview in tests.
--! @details
--! This file contains the top level testbench and combines all error states of the testbenches in the UART_Extension_Pack project. 
--!
--! It tests all components by using the testbenches as components.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_UART_Extension_Pack is
  Port (
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_UART_Extension_Pack;

architecture TESTBENCH of TB_UART_Extension_Pack is
  component TB_Main_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_ExtPack_Management
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
  component TB_GPIO_Bank_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Timer_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Timer_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_UART_Module
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_SPI_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_SPI_Module
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_I2C_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_I2C_Module
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_ISSI_IS61WV5128BLL_SRAM_Wrapper
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_ISSI_IS61WV5128BLL_SRAM_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Reset_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_Error_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_ACK_Unit
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_IO_Sync
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_IO_Sync_Vector
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_MUX
    Port(
      signal tb_error : out std_logic
    );
  end component;
  component TB_DEMUX
    Port(
      signal tb_error : out std_logic
    );
  end component;
  signal tb_error_TB_Main_Unit : std_logic;
  signal tb_error_TB_ExtPack_Management : std_logic;
  signal tb_error_TB_Decoder : std_logic;
  signal tb_error_TB_PriorityScheduler : std_logic;
  signal tb_error_TB_Encoder : std_logic;
  signal tb_error_TB_UART_Wrapper : std_logic;
  signal tb_error_TB_GPIO_Wrapper : std_logic;
  signal tb_error_TB_GPIO_Bank_Unit : std_logic;
  signal tb_error_TB_Timer_Wrapper : std_logic;
  signal tb_error_TB_Timer_Unit : std_logic;
  signal tb_error_TB_SPI_Wrapper : std_logic;
  signal tb_error_TB_SPI_Module : std_logic;
  signal tb_error_TB_I2C_Wrapper : std_logic;
  signal tb_error_TB_I2C_Module : std_logic;
  signal tb_error_TB_ISSI_IS61WV5128BLL_SRAM_Wrapper : std_logic;
  signal tb_error_TB_ISSI_IS61WV5128BLL_SRAM_Unit : std_logic;
  signal tb_error_TB_UART_Module : std_logic;
  signal tb_error_TB_Reset_Unit : std_logic;
  signal tb_error_TB_Error_Unit : std_logic;
  signal tb_error_TB_ACK_Unit : std_logic;
  signal tb_error_TB_IO_Sync : std_logic;
  signal tb_error_TB_IO_Sync_Vector : std_logic;
  signal tb_error_TB_MUX : std_logic;
  signal tb_error_TB_DEMUX : std_logic;
begin
  Main_Unit: TB_Main_Unit port map(tb_error_TB_Main_Unit);
  ExtPack_Management: TB_ExtPack_Management port map(tb_error_TB_ExtPack_Management);
  Decoder: TB_Decoder port map(tb_error_TB_Decoder);
  PriorityScheduler: TB_PriorityScheduler port map(tb_error_TB_PriorityScheduler);
  Encoder: TB_Encoder port map(tb_error_TB_Encoder);
  UART_Wrapper: TB_UART_Wrapper port map(tb_error_TB_UART_Wrapper);
  GPIO_Wrapper: TB_GPIO_Wrapper port map(tb_error_TB_GPIO_Wrapper);
  GPIO_Bank_Unit: TB_GPIO_Bank_Unit port map(tb_error_TB_GPIO_Bank_Unit);
  Timer_Wrapper: TB_Timer_Wrapper port map(tb_error_TB_Timer_Wrapper);
  Timer_Unit: TB_Timer_Unit port map(tb_error_TB_Timer_Unit);
  SPI_Wrapper: TB_SPI_Wrapper port map(tb_error_TB_SPI_Wrapper);
  SPI_MODULE: TB_SPI_Module port map(tb_error_TB_SPI_Module);
  I2C_Wrapper: TB_I2C_Wrapper port map(tb_error_TB_I2C_Wrapper);
  I2C_MODULE: TB_I2C_Module port map(tb_error_TB_I2C_Module);
  SRAM_ISSI_Wrapper: TB_ISSI_IS61WV5128BLL_SRAM_Wrapper port map(tb_error_TB_ISSI_IS61WV5128BLL_SRAM_Wrapper);
  SRAM_ISSI_Unit: TB_ISSI_IS61WV5128BLL_SRAM_Unit port map(tb_error_TB_ISSI_IS61WV5128BLL_SRAM_Unit);
  UART_Module: TB_UART_Module port map(tb_error_TB_UART_Module);
  Reset_Unit: TB_Reset_Unit port map(tb_error_TB_Reset_Unit);
  Error_Unit: TB_Error_Unit port map(tb_error_TB_Error_Unit);
  ACK_Unit: TB_ACK_Unit port map(tb_error_TB_ACK_Unit);
  IO_Sync: TB_IO_Sync port map(tb_error_TB_IO_Sync);
  IO_Sync_Vector: TB_IO_Sync_Vector port map(tb_error_TB_IO_Sync_Vector);
  MUX: TB_MUX port map(tb_error_TB_MUX);
  DEMUX: TB_DEMUX port map(tb_error_TB_DEMUX);

  tb_error <= '0' when 
    (tb_error_TB_Main_Unit = '0')
    and (tb_error_TB_ExtPack_Management = '0')
    and (tb_error_TB_Decoder = '0')
    and (tb_error_TB_PriorityScheduler = '0')
    and (tb_error_TB_Encoder = '0')
    and (tb_error_TB_UART_Wrapper = '0')
    and (tb_error_TB_GPIO_Wrapper = '0')
    and (tb_error_TB_GPIO_Bank_Unit = '0')
    and (tb_error_TB_Timer_Wrapper = '0') 
    and (tb_error_TB_Timer_Unit = '0') 
    and (tb_error_TB_SPI_Wrapper = '0') 
    and (tb_error_TB_SPI_Module = '0') 
    and (tb_error_TB_I2C_Wrapper = '0') 
    and (tb_error_TB_I2C_Module = '0') 
    and (tb_error_TB_ISSI_IS61WV5128BLL_SRAM_Wrapper = '0') 
    and (tb_error_TB_ISSI_IS61WV5128BLL_SRAM_Unit = '0') 
    and (tb_error_TB_UART_Module = '0') 
    and (tb_error_TB_Reset_Unit = '0') 
    and (tb_error_TB_Error_Unit = '0') 
    and (tb_error_TB_ACK_Unit = '0')
    and (tb_error_TB_IO_Sync = '0') 
    and (tb_error_TB_IO_Sync_Vector = '0') 
    and (tb_error_TB_MUX = '0') 
    and (tb_error_TB_DEMUX = '0') else '1';

end TESTBENCH;