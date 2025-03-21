library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_GPIO_Wrapper is
end TB_GPIO_Wrapper;

architecture Behavioral of TB_GPIO_Wrapper is
  component GPIO_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN/OUT_PINS <= HOST_DATA_BITS has to be fullfilled
      -- IN/OUT_PINS >= 1 has to be fullfilled
      IN_PINS : integer := 8;
      OUT_PINS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
      unit_data_in : in STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      gpio_data_in : in STD_LOGIC_VECTOR (IN_PINS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (OUT_PINS-1 downto 0)
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en : std_logic;
  signal tb_access_mode : std_logic_vector(1 downto 0); --*0: set, *1: get
  signal tb_unit_data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done : std_logic;
  signal tb_gpio_data_in : STD_LOGIC_VECTOR (0 downto 0);
  signal tb_gpio_data_out, tb_exp_gpio_data_out : STD_LOGIC_VECTOR (0 downto 0);

  constant tbase : time := 100 ns;
  signal tb_error : std_logic;
begin
  COMP: GPIO_Wrapper generic map(8, 1, 1) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_gpio_data_in, tb_gpio_data_out);

  -- 10 MHz
  CLOCK: process
  begin
    for i in 1000 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 1*tbase;

  tb_write_en <= '0',
    '1' after 2*tbase, '0' after 3*tbase,
    '1' after 12*tbase, '0' after 13*tbase,
    '1' after 22*tbase, '0' after 23*tbase;

  tb_access_mode <= "00",
    "00" after 2*tbase,
    "00" after 12*tbase,
    "01" after 22*tbase;

  tb_unit_data_in <= "00000000",
    "00000001" after 2*tbase,
    "00000000" after 12*tbase,
    "00000000" after 22*tbase;

  tb_scheduler_done <= '0',
    '1' after 9.5*tbase, '0' after 11*tbase,
    '1' after 33.5*tbase, '0' after 35*tbase;

  tb_gpio_data_in <= "0",
    "1" after 5.5*tbase;

  -- one clock cycle delayed because of GPIO Bank Unit register (only for interrupts)
  tb_exp_unit_data_out <= "00000000",
    "00000001" after 6*tbase,
    "00000001" after 22*tbase;

  -- one clock cycle delayed because of GPIO Bank Unit input sync register
  tb_exp_scheduler_wanted <= '0',
    '1' after 6*tbase, '0' after 9.5*tbase,
    '1' after 22*tbase, '0' after 33.5*tbase;

  -- one clock cycle delayed because of GPIO Bank Unit register (only for interrupts)
  tb_exp_gpio_data_out <= "0",
    "1" after 3*tbase,
    "0" after 13*tbase;
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_gpio_data_out = tb_gpio_data_out) else '1';




end Behavioral;
