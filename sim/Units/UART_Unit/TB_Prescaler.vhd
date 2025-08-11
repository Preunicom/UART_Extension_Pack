library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Prescaler is
  Port (
    tb_error : out std_logic
  );
end TB_Prescaler;

architecture TESTBENCH of TB_Prescaler is
  component Prescaler
    generic (
      -- IN_FREQ_HZ has to be minimum 2*BAUD_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600
    );
    port (
      clk, rst      : in  STD_LOGIC;
      clk_en_prescaled : out STD_LOGIC
    );
  end component;
  signal tb_clk, tb_rst : STD_LOGIC;
  signal tb_clk_en_prescaled : STD_LOGIC;
  signal tb_exp_clk_en_prescaled : STD_LOGIC := 'U';
  constant tbase : time := 100 ns;
  constant tbase_exp : time := 1000 ns;
begin
  COMP: Prescaler generic map(10000000, 1000000) port map(tb_clk, tb_rst, tb_clk_en_prescaled);

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

  -- 1 MHz
  CLOCK_EXP: process
  begin
    wait for 1*tbase;
    tb_exp_clk_en_prescaled <= '0';
    wait for 4*tbase;
    for i in 100 downto 0 loop
      tb_exp_clk_en_prescaled <= '1';
      wait for 1*tbase;
      tb_exp_clk_en_prescaled <= '0';
      wait for tbase_exp-tbase;
    end loop;
    wait;
  end process;

  tb_error <= '0' when (tb_exp_clk_en_prescaled = tb_clk_en_prescaled) else '1';


end TESTBENCH;
