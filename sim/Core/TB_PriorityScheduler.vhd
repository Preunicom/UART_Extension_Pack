library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_PriorityScheduler is
  Port(
    signal tb_error : out std_logic
  );
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
  signal tb_scheduler_done, tb_exp_scheduler_done : std_logic_vector(63 downto 0);

  constant tbase : time := 100 ns;
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

  tb_rst <= '1', '0' after 2*tbase;

  tb_schedule_next <= '1', '0' after 11*tbase,
    '1' after 20*tbase, '0' after 22*tbase,
    '1' after 30*tbase, '0' after 32*tbase,
    '1' after 40*tbase, '0' after 42*tbase,
    '1' after 50*tbase, '0' after 102*tbase,
    '1' after 110*tbase;

  tb_scheduler_wanted(4) <= '1' after 101*tbase, '0' after 111*tbase; -- fifth (0x10)
  tb_scheduler_wanted(3) <= '1' after 5*tbase, '0' after 21*tbase; -- first (0x08)
  tb_scheduler_wanted(2) <= '1' after 11*tbase, '0' after 51*tbase; -- forth (0x04)
  tb_scheduler_wanted(1) <= '1' after 19*tbase, '0' after 31*tbase; -- second (0x02)
  tb_scheduler_wanted(0) <= '1' after 25*tbase, '0' after 41*tbase; -- third (0x01)

  tb_exp_control_sig <= "UUUUUU", "000000" after 1*tbase,
    "000011" after 5*tbase,
    "000001" after 21*tbase,
    "000000" after 31*tbase,
    "000010" after 41*tbase,
    "000000" after 51*tbase,
    "000100" after 101*tbase,
    "000000" after 111*tbase;

  tb_exp_outp_valid <= 'U', '0' after 1*tbase,
    '1' after 5*tbase, '0' after 11*tbase,
    '1' after 21*tbase, '0' after 22*tbase,
    '1' after 31*tbase, '0' after 32*tbase,
    '1' after 41*tbase, '0' after 42*tbase,
    '1' after 101*tbase, '0' after 102*tbase;

  tb_exp_scheduler_done(63 downto 5) <= (others => 'U'), (others => '0') after 1*tbase;

  tb_exp_scheduler_done(4) <= 'U', '0' after 1*tbase, '1' after 102*tbase, '0' after 103*tbase;
  tb_exp_scheduler_done(3) <= 'U', '0' after 1*tbase, '1' after 11*tbase, '0' after 12*tbase;
  tb_exp_scheduler_done(2) <= 'U', '0' after 1*tbase, '1' after 42*tbase, '0' after 43*tbase;
  tb_exp_scheduler_done(1) <= 'U', '0' after 1*tbase, '1' after 22*tbase, '0' after 23*tbase;
  tb_exp_scheduler_done(0) <= 'U', '0' after 1*tbase, '1' after 32*tbase, '0' after 33*tbase;
  
  tb_error <= '0' when 
    (tb_exp_control_sig = tb_control_sig)
    and (tb_exp_outp_valid = tb_outp_valid)
    and (tb_exp_scheduler_done = tb_scheduler_done) else '1';


end Behavioral;
