--! @file
--! @brief Testbench for the Timer_Unit
--! @details
--! This file contains the testbench for the Timer_Unit entity.  
--! It tests:
--! - Set prescaler
--! - enable
--! - set start value
--! - restart timer

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Timer_Unit is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_Timer_Unit;

architecture TESTBENCH of TB_Timer_Unit is
  component Timer_Unit
    generic (
      WIDTH : integer := 8;
      IN_FREQ : integer := 12000000;
      BASE_FREQ : integer := 50000
    );
    port (
      clk : in std_logic;
      rst : in std_logic;
      en : in std_logic;
      prescale_factor_write_en : in std_logic; 
      prescale_factor : in integer;
      start_value_write_en : in std_logic;
      start_value : in unsigned(WIDTH-1 downto 0);
      restart_timer : in std_logic;
      is_timer_end : out std_logic
    );
  end component;

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_en : std_logic;
  signal tb_prescale_factor_write_en : std_logic; 
  signal tb_prescale_factor : integer;
  signal tb_start_value_write_en : std_logic;
  signal tb_start_value : unsigned(7 downto 0);
  signal tb_restart_timer : std_logic;
  signal tb_is_timer_end, tb_exp_timer_end : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: Timer_Unit generic map(8, 10000000, 5000) port map(tb_clk, tb_rst, tb_en, tb_prescale_factor_write_en, tb_prescale_factor, tb_start_value_write_en, tb_start_value, tb_restart_timer, tb_is_timer_end);

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

  tb_en <= '0',
    '1' after 21*tbase, '0' after 280*tbase;

  tb_prescale_factor_write_en <= '0',
    '1' after 20*tbase, '1' after 21*tbase;

  tb_prescale_factor <= 0,
    2 after 20*tbase, 0 after 21*tbase;

  tb_start_value_write_en <= '0',
    '1' after 20*tbase, '1' after 21*tbase;

  tb_start_value <= (others => '0'),
    x"FE" after 20*tbase, x"00" after 21*tbase;

  tb_restart_timer <= '0',
    '1' after 21*tbase, '0' after 22*tbase;

  tb_exp_timer_end <= 'U', '0' after 1*tbase,
    '1' after 278*tbase, '0' after 279*tbase;

  tb_error <= '0' when 
    (tb_exp_timer_end = tb_is_timer_end) else '1';

end TESTBENCH;