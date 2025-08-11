library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_I2C_Module is
  Port (
    tb_error : out std_logic
  );
end TB_I2C_Module;

architecture TESTBENCH of TB_I2C_Module is
  component TB_I2C_Prescaler
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_I2C_Communication
    Port (
      tb_error : out std_logic
    );
  end component;
  component TB_I2C_Unit
    Port (
      tb_error : out std_logic
    );
  end component;
  signal tb_error_TB_I2C_Prescaler : std_logic;
  signal tb_error_TB_I2C_Communication : std_logic;
  signal tb_error_TB_I2C_Unit : std_logic;
begin
  I2C_Prescaler: TB_I2C_Prescaler port map(tb_error_TB_I2C_Prescaler);
  I2C_Communiction: TB_I2C_Communication port map(tb_error_TB_I2C_Communication);
  I2C_Unit: TB_I2C_Unit port map(tb_error_TB_I2C_Unit);

  tb_error <= '0' when 
    (tb_error_TB_I2C_Prescaler = '0')
    and (tb_error_TB_I2C_Communication = '0')
    and (tb_error_TB_I2C_Unit = '0') else '1';

end TESTBENCH;
