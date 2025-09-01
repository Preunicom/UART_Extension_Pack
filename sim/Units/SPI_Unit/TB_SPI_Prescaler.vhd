--! @file
--! @brief Testbench for the SPI_Prescaler
--! @details
--! This file contains the testbench for the SPI_Prescaler entity.
--! It tests:
--! - Normal operation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_Prescaler is
  Port (
    tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_SPI_Prescaler;

architecture TESTBENCH of TB_SPI_Prescaler is
  component SPI_Prescaler
    generic (
      -- IN_FREQ_HZ has to be minimum 2*OUT_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0
    );
    port (
      clk, rst      : in  STD_LOGIC;
      clk_prescaled_rising_edge : out STD_LOGIC;
      clk_prescaled_falling_edge : out STD_LOGIC
    );
  end component;
  signal tb_clk, tb_rst : STD_LOGIC;
  signal tb_clk_prescaled_rising_edge : STD_LOGIC := 'U';
  signal tb_clk_prescaled_falling_edge : STD_LOGIC := 'U';
  signal tb_exp_clk_prescaled_rising_edge : STD_LOGIC := 'U';
  signal tb_exp_clk_prescaled_falling_edge : STD_LOGIC := 'U';
  constant tbase : time := 100 ns;
begin
  COMP: SPI_Prescaler generic map(10000000, 1000000, 8, 0) port map(tb_clk, tb_rst, tb_clk_prescaled_rising_edge, tb_clk_prescaled_falling_edge);

  tb_rst <= '1', '0' after 2*tbase;

  -- 10 MHz
  CLOCK: process
  begin
    for i in 1012 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_exp_clk_prescaled_falling_edge <= 'U', '0' after 1*tbase,
    '1' after 11*tbase, '0' after 12*tbase,
    '1' after 21*tbase, '0' after 22*tbase,
    '1' after 31*tbase, '0' after 32*tbase,
    '1' after 41*tbase, '0' after 42*tbase,
    '1' after 51*tbase, '0' after 52*tbase,
    '1' after 61*tbase, '0' after 62*tbase,
    '1' after 71*tbase, '0' after 72*tbase,
    '1' after 81*tbase, '0' after 82*tbase;

  tb_exp_clk_prescaled_rising_edge <= 'U', '0' after 1*tbase,
    '1' after 6*tbase, '0' after 7*tbase,
    '1' after 16*tbase, '0' after 17*tbase,
    '1' after 26*tbase, '0' after 27*tbase,
    '1' after 36*tbase, '0' after 37*tbase,
    '1' after 46*tbase, '0' after 47*tbase,
    '1' after 56*tbase, '0' after 57*tbase,
    '1' after 66*tbase, '0' after 67*tbase,
    '1' after 76*tbase, '0' after 77*tbase;

  tb_error <= '0' when 
  (tb_exp_clk_prescaled_rising_edge = tb_clk_prescaled_rising_edge)
  and (tb_exp_clk_prescaled_falling_edge = tb_clk_prescaled_falling_edge)  else '1';

end TESTBENCH;
