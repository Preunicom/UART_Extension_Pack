library IEEE;
  use IEEE.STD_LOGIC_1164.all;

entity TB_Timer_Wrapper is
end entity;

architecture Behavioral of TB_Timer_Wrapper is
  component Timer_Wrapper
    generic (
      HOST_DATA_BITS : integer := 8;
      FPGA_FREQ      : integer := 12000000;
      HOST_BAUD      : integer := 1000000
    );
    port (
      clk, rst         : in  STD_LOGIC;
      write_en         : in  std_logic;
      access_mode      : in  std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
      unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      unit_data_out    : out STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done   : in  std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en                                  : std_logic;
  signal tb_access_mode                               : std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
  signal tb_unit_data_in                              : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out       : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done                            : std_logic;

  constant tbase : time := 100 ns;
  signal tb_error : std_logic;
begin
  COMP: Timer_Wrapper generic map(8, 10000000, 1000000) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done);

  -- 10 MHz
  CLOCK: process
  begin
    for i in 5000 downto 0 loop
      tb_clk <= '1';
      wait for tbase / 2;
      tb_clk <= '0';
      wait for tbase / 2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 1 * tbase;

  tb_write_en <= '0',
    '1' after 2*tbase, '0' after 3*tbase, -- set start_value (0xFF)
    '1' after 212*tbase, '0' after 213*tbase, -- restart
    '1' after 222*tbase, '0' after 223*tbase, -- en
    '1' after 290*tbase, '0' after 291*tbase, -- set start_value (0xFE)
    '1' after 1400*tbase, '0' after 1401*tbase, -- set prescale factor
    '1' after 2400*tbase, '0' after 2401*tbase, -- set start_value (0xFF)
    '1' after 4000*tbase, '0' after 4001*tbase; -- en

  tb_access_mode <= "00",
    "11" after 2*tbase,
    "01" after 212*tbase,
    "00" after 222*tbase,
    "11" after 290*tbase,
    "10" after 1400*tbase,
    "11" after 2400*tbase,
    "00" after 4000*tbase;

  tb_unit_data_in <= "00000000",
    "11111111" after 2*tbase,
    "00000000" after 212*tbase,
    "11111111" after 222*tbase,
    "11111110" after 290*tbase,
    "00000010" after 1400*tbase,
    "11111111" after 2400*tbase,
    "00000000" after 4000*tbase;

  tb_scheduler_done <= '0',
    '1' after 320.5*tbase, '0' after 322*tbase,
    '1' after 530.5*tbase, '0' after 532*tbase,
    '1' after 930.5*tbase, '0' after 932*tbase,
    '1' after 1390.5*tbase, '0' after 1392*tbase,
    '1' after 1790.5*tbase, '0' after 1792*tbase,
    '1' after 2590.5*tbase, '0' after 2592*tbase,
    '1' after 2990.5*tbase, '0' after 2992*tbase,
    '1' after 3390.5*tbase, '0' after 3392*tbase,
    '1' after 3790.5*tbase, '0' after 3792*tbase;

  -- value not used in Timer unit
  tb_exp_unit_data_out <= "11111111";

  tb_exp_scheduler_wanted <= '0',
    '1' after 300*tbase, '0' after 320.5*tbase,
    '1' after 500*tbase, '0' after 530.5*tbase,
    '1' after 900*tbase, '0' after 930.5*tbase,
    '1' after 1300*tbase, '0' after 1390.5*tbase,
    '1' after 1700*tbase, '0' after 1790.5*tbase,
    '1' after 2500*tbase, '0' after 2590.5*tbase,
    '1' after 2900*tbase, '0' after 2990.5*tbase,
    '1' after 3300*tbase, '0' after 3390.5*tbase,
    '1' after 3700*tbase, '0' after 3790.5*tbase;
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted) else '1';

end architecture;