
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_PriorityScheduler is
end TB_PriorityScheduler;

architecture Behavioral of TB_PriorityScheduler is
  component PriorityScheduler
    Port ( 
      clk, rst : in STD_LOGIC;
      schedule_next : in std_logic;
      outp_valid : out std_logic;
      control_sig : out std_logic_vector(5 downto 0);
      scheduler_wanted : in std_logic_vector(63 downto 0);
      scheduler_done : out std_logic_vector(63 downto 0)
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_schedule_next : std_logic;
  signal tb_outp_valid, tb_exp_outp_valid : std_logic;
  signal tb_control_sig, tb_exp_control_sig : std_logic_vector(5 downto 0);
  signal tb_scheduler_wanted : std_logic_vector(63 downto 0) := (others => '0');
  signal tb_scheduler_done, tb_exp_scheduler_done : std_logic_vector(63 downto 0) := (others => '0');

  constant tbase : time := 100 ns;
  signal tb_error : std_logic;
begin
  COMP: PriorityScheduler port map(tb_clk, tb_rst, tb_schedule_next, tb_outp_valid, tb_control_sig, tb_scheduler_wanted, tb_scheduler_done);

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

  -- these updates async --> half a clock cycle earlies than the schedule sync process works with it
  tb_schedule_next <= '0',
    '1' after 9.5*tbase, '0' after 11*tbase,
    '1' after 19.5*tbase, '0' after 21*tbase,
    '1' after 29.5*tbase, '0' after 31*tbase,
    '1' after 39.5*tbase, '0' after 41*tbase,
    '1' after 49.5*tbase, '0' after 101*tbase,
    '1' after 109.5*tbase;

  --These signals updates async to 0 right after schedule next --> half a clock cycle before schedule next
  tb_scheduler_wanted(4) <= '1' after 100*tbase, '0' after 109.5*tbase;
  tb_scheduler_wanted(3) <= '1' after 5*tbase, '0' after 19.5*tbase;
  tb_scheduler_wanted(2) <= '1' after 11*tbase, '0' after 49.5*tbase;
  tb_scheduler_wanted(1) <= '1' after 19*tbase, '0' after 29.5*tbase;
  tb_scheduler_wanted(0) <= '1' after 25*tbase, '0' after 39.5*tbase;

  tb_exp_control_sig <= "000000",
    "000011" after 10*tbase,
    "000001" after 20*tbase,
    "000000" after 30*tbase,
    "000010" after 40*tbase,
    "000000" after 50*tbase,
    "000100" after 100*tbase,
    "000000" after 110*tbase;

  tb_exp_outp_valid <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 20*tbase, '0' after 21*tbase,
    '1' after 30*tbase, '0' after 31*tbase,
    '1' after 40*tbase, '0' after 41*tbase,
    '1' after 100*tbase, '0' after 101*tbase;

  tb_exp_scheduler_done(4) <= '1' after 109.5*tbase;
  tb_exp_scheduler_done(3) <= '1' after 19.5*tbase, '0' after 21*tbase;
  tb_exp_scheduler_done(2) <= '1' after 49.5*tbase, '0' after 101*tbase;
  tb_exp_scheduler_done(1) <= '1' after 29.5*tbase, '0' after 31*tbase;
  tb_exp_scheduler_done(0) <= '1' after 39.5*tbase, '0' after 41*tbase;
  
  tb_error <= '0' when 
    (tb_exp_control_sig = tb_control_sig)
    and (tb_exp_outp_valid = tb_outp_valid)
    and (tb_exp_scheduler_done = tb_scheduler_done) else '1';


end Behavioral;
