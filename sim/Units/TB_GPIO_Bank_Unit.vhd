--! @file
--! @brief Testbench for the GPIO_Bank_Unit
--! @details
--! This file contains the testbench for the GPIO_Bank_Unit entity.  
--! It tests:
--! - Set
--! - Get
--! - Set without enable --> Ignored

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_GPIO_Bank_Unit is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_GPIO_Bank_Unit;

architecture TESTBENCH of TB_GPIO_Bank_Unit is
  component GPIO_Bank_Unit is
    Generic (
      INPUTS : integer := 8;
      OUTPUTS : integer := 8
    );
    Port (
      clk : in std_logic;
      rst : in std_logic;
      write_en : in std_logic;
      config_in : in STD_LOGIC_VECTOR(OUTPUTS-1 downto 0);
      values_out : out STD_LOGIC_VECTOR(INPUTS-1 downto 0);
      gpio_data_in : in STD_LOGIC_VECTOR (INPUTS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (OUTPUTS-1 downto 0)
    );
  end component;

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  constant OUTPUTS: integer := 4;
  constant INPUTS: integer := 8;

  signal tb_write_en : std_logic;
  signal tb_config_in : STD_LOGIC_VECTOR(OUTPUTS-1 downto 0);
  signal tb_values_out, tb_exp_values_out : STD_LOGIC_VECTOR(INPUTS-1 downto 0);
  signal tb_gpio_data_in : STD_LOGIC_VECTOR (INPUTS-1 downto 0);
  signal tb_gpio_data_out, tb_exp_gpio_data_out : STD_LOGIC_VECTOR (OUTPUTS-1 downto 0);

  constant tbase : time := 100 ns;
begin
  COMP: GPIO_Bank_Unit generic map(INPUTS, OUTPUTS) port map(tb_clk, tb_rst, tb_write_en, tb_config_in, tb_values_out, tb_gpio_data_in, tb_gpio_data_out);

  -- 10 MHz
  CLOCK: process
  begin
    for i in 20000 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_write_en <= '0',
    '1' after 30*tbase, '0' after 31*tbase;

  tb_config_in <= (others => '0'),
    x"3" after 30*tbase,
    x"3" after 50*tbase; -- Should be ignored (no enable)

  tb_exp_values_out <= (others => '0'),
    x"63" after 40*tbase;

  tb_gpio_data_in <= (others => '0'),
    x"63" after 40*tbase;

  tb_exp_gpio_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    x"3" after 30*tbase;

  tb_error <= '0' when
    (tb_exp_gpio_data_out = tb_gpio_data_out) 
    and (tb_exp_values_out = tb_values_out) else '1';

end TESTBENCH;