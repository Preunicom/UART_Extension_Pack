--! @file
--! @brief Top level testbench combining all tb_error signals of all testbenches related to SPI_Unit to show an overview in tests.
--! @details
--! This file contains the top level testbench and combines all error states of the testbenches in the SPI_Unit project. 
--!
--! It tests all SPI_Unit components by using the testbenches as components.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_Module is
  Port (
    tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_SPI_Module;

architecture TESTBENCH of TB_SPI_Module is
  component TB_SPI_Unit
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Unit_Mode0
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Unit_Mode1
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Unit_Mode2
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Unit_Mode3
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Prescaler
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_CLK_Manager
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Deserializer
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Buffer_Register_Deserializer
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Serializer
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_SPI_Buffer_Register_Serializer
    Port (
      tb_error : out std_logic
    );
  end component;
  signal tb_error_TB_SPI_Unit : std_logic;
  signal tb_error_TB_SPI_Unit_Mode0 : std_logic;
  signal tb_error_TB_SPI_Unit_Mode1 : std_logic;
  signal tb_error_TB_SPI_Unit_Mode2 : std_logic;
  signal tb_error_TB_SPI_Unit_Mode3 : std_logic;
  signal tb_error_TB_SPI_Prescaler : std_logic;
  signal tb_error_TB_SPI_CLK_Manager : std_logic;
  signal tb_error_TB_SPI_Deserializer : std_logic;
  signal tb_error_TB_SPI_Buffer_Register_Deserializer : std_logic;
  signal tb_error_TB_SPI_Serializer : std_logic;
  signal tb_error_TB_SPI_Buffer_Register_Serializer : std_logic;
begin
  SPI_Unit: TB_SPI_Unit port map(tb_error_TB_SPI_Unit);
  SPI_Unit_M0: TB_SPI_Unit_Mode0 port map(tb_error_TB_SPI_Unit_Mode0);
  SPI_Unit_M1: TB_SPI_Unit_Mode1 port map(tb_error_TB_SPI_Unit_Mode1);
  SPI_Unit_M2: TB_SPI_Unit_Mode2 port map(tb_error_TB_SPI_Unit_Mode2);
  SPI_Unit_M3: TB_SPI_Unit_Mode3 port map(tb_error_TB_SPI_Unit_Mode3);
  SPI_Prescaler: TB_SPI_Prescaler port map(tb_error_TB_SPI_Prescaler);
  SPI_CLK_Manager: TB_SPI_CLK_Manager port map(tb_error_TB_SPI_CLK_Manager);
  SPI_Deserializer: TB_SPI_Deserializer port map(tb_error_TB_SPI_Deserializer);
  SPI_Buffer_Register_Deserializer: TB_SPI_Buffer_Register_Deserializer port map(tb_error_TB_SPI_Buffer_Register_Deserializer);
  SPI_Serializer: TB_SPI_Serializer port map(tb_error_TB_SPI_Serializer);
  SPI_Buffer_Register_Serializer: TB_SPI_Buffer_Register_Serializer port map(tb_error_TB_SPI_Buffer_Register_Serializer);

  tb_error <= '0' when 
    (tb_error_TB_SPI_Unit = '0')
    and (tb_error_TB_SPI_Unit_Mode0 = '0')
    and (tb_error_TB_SPI_Unit_Mode1 = '0')
    and (tb_error_TB_SPI_Unit_Mode2 = '0')
    and (tb_error_TB_SPI_Unit_Mode3 = '0')
    and (tb_error_TB_SPI_Prescaler = '0')
    and (tb_error_TB_SPI_CLK_Manager = '0')
    and (tb_error_TB_SPI_Deserializer = '0')
    and (tb_error_TB_SPI_Buffer_Register_Deserializer = '0')
    and (tb_error_TB_SPI_Serializer = '0')
    and (tb_error_TB_SPI_Buffer_Register_Serializer = '0') else '1';

end TESTBENCH;
