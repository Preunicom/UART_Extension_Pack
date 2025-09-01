--! @file
--! @brief Testbench for the I2C_Prescaler
--! @details
--! This file contains the testbench for the I2C_Prescaler entity.
--! It tests:
--! - Normal operation from 10MHz to 1 MHz

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_I2C_Prescaler is
  Port (
    tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_I2C_Prescaler;

architecture TESTBENCH of TB_I2C_Prescaler is
  component I2C_Prescaler
    generic (
      -- IN_FREQ_HZ has to be minimum 4*OUT_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      OUT_FREQ_HZ : integer := 100000
    );
    port (
      clk, rst : in  STD_LOGIC;
      clk_en_read : out std_logic;
      clk_en_write : out std_logic;
      SCL_in : in std_logic;
      SCL_out : out std_logic
    );
  end component;

  signal tb_clk  : std_logic := '0';
  signal tb_rst  : std_logic := '1';
  signal tb_clk_en_read, tb_exp_clk_en_read : std_logic;
  signal tb_clk_en_write, tb_exp_clk_en_write : std_logic;
  signal tb_SCL, tb_exp_SCL, tb_SCL_no_pullup : std_logic;
  constant tbase : time := 100 ns;

begin
  COMP: I2C_Prescaler generic map(10000000, 1000000) port map(tb_clk, tb_rst, tb_clk_en_read, tb_clk_en_write, tb_SCL, tb_SCL_no_pullup);

  tb_SCL <= tb_SCL_no_pullup when tb_SCL_no_pullup /= 'Z' else '1';

  -- 10 MHz
  CLOCK: process
  begin
    for i in 100 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_exp_clk_en_read <= '0',
    '1' after 8*tbase, '0' after 9*tbase,
    '1' after 18*tbase, '0' after 19*tbase,
    '1' after 28*tbase, '0' after 29*tbase,
    '1' after 38*tbase, '0' after 39*tbase,
    '1' after 48*tbase, '0' after 49*tbase,
    '1' after 58*tbase, '0' after 59*tbase,
    '1' after 68*tbase, '0' after 69*tbase,
    '1' after 78*tbase, '0' after 79*tbase,
    '1' after 88*tbase, '0' after 89*tbase,
    '1' after 98*tbase, '0' after 99*tbase;

  tb_exp_clk_en_write <= '0',
    '1' after 3*tbase, '0' after 4*tbase,
    '1' after 13*tbase, '0' after 14*tbase,
    '1' after 23*tbase, '0' after 24*tbase,
    '1' after 33*tbase, '0' after 34*tbase,
    '1' after 43*tbase, '0' after 44*tbase,
    '1' after 53*tbase, '0' after 54*tbase,
    '1' after 63*tbase, '0' after 64*tbase,
    '1' after 73*tbase, '0' after 74*tbase,
    '1' after 83*tbase, '0' after 84*tbase,
    '1' after 93*tbase, '0' after 94*tbase;

  tb_exp_SCL <= '0',
    '1' after 6*tbase, '0' after 11*tbase,
    '1' after 16*tbase, '0' after 21*tbase,
    '1' after 26*tbase, '0' after 31*tbase,
    '1' after 36*tbase, '0' after 41*tbase,
    '1' after 46*tbase, '0' after 51*tbase,
    '1' after 56*tbase, '0' after 61*tbase,
    '1' after 66*tbase, '0' after 71*tbase,
    '1' after 76*tbase, '0' after 81*tbase,
    '1' after 86*tbase, '0' after 91*tbase,
    '1' after 96*tbase;

    tb_error <= '0' when
    (tb_exp_clk_en_read = tb_clk_en_read)
    and (tb_exp_clk_en_write = tb_clk_en_write)
    and (tb_exp_SCL = tb_SCL) else '1';

end TESTBENCH;
