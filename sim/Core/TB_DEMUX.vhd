--! @file
--! @brief Testbench for the DEMUX
--! @details
--! This file contains the testbench for the DEMUX entity.  
--! It tests:
--! - Normal operation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_DEMUX is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_DEMUX;

architecture TESTBENCH of TB_DEMUX is
  component DEMUX
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk : in std_logic;
      rst : in std_logic;
      control : in STD_LOGIC_VECTOR(5 downto 0);
      inp_en : in STD_LOGIC;
      inp_data : in std_logic_vector(DATA_BITS-1 downto 0);
      inp_acc_mode : in std_logic_vector(1 downto 0);
      outp_en : out STD_LOGIC_VECTOR(63 downto 0);
      outp_data : out std_logic_vector(DATA_BITS-1 downto 0);
      outp_acc_mode : out std_logic_vector(1 downto 0)
    );
  end component;

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_control : STD_LOGIC_VECTOR(5 downto 0);
  signal tb_inp_en : STD_LOGIC;
  signal tb_inp_data : std_logic_vector(7 downto 0);
  signal tb_inp_acc_mode : std_logic_vector(1 downto 0);
  signal tb_outp_en, tb_exp_outp_en : STD_LOGIC_VECTOR(63 downto 0);
  signal tb_outp_data, tb_exp_outp_data : std_logic_vector(7 downto 0);
  signal tb_outp_acc_mode, tb_exp_outp_acc_mode : std_logic_vector(1 downto 0);

  constant tbase : time := 100 ns;
begin
  COMP: DEMUX generic map(8) port map(tb_clk, tb_rst, tb_control, tb_inp_en, tb_inp_data, tb_inp_acc_mode, tb_outp_en, tb_outp_data, tb_outp_acc_mode);

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

  tb_control <= (others => '0'),
    "111111" after 20*tbase, (others => '0') after 30*tbase;

  tb_inp_en <= '0',
    '1' after 22*tbase, '0' after 27*tbase;

  tb_inp_data <= (others => '0'),
    x"73" after 22*tbase, x"00" after 27*tbase;

  tb_inp_acc_mode <= (others => '0'),
    "01" after 22*tbase, "00" after 27*tbase;

  tb_exp_outp_en(62 downto 0) <= (others => 'U'), (others => '0') after 1*tbase;
  tb_exp_outp_en(63) <= 'U', '0' after 1*tbase, '1' after 22*tbase, '0' after 27*tbase;

  tb_exp_outp_data <= (others => 'U'), (others => '0') after 1*tbase,
    x"73" after 22*tbase, x"00" after 27*tbase;

  tb_exp_outp_acc_mode <= (others => 'U'), (others => '0') after 1*tbase,
    "01" after 22*tbase, "00" after 27*tbase;

  tb_error <= '0' when
    (tb_exp_outp_acc_mode = tb_outp_acc_mode) 
    and (tb_exp_outp_data = tb_outp_data) 
    and (tb_exp_outp_en = tb_outp_en) else '1';

end TESTBENCH;