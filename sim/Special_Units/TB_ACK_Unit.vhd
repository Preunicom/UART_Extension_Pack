--! @file
--! @brief Testbench for the ACK_Unit
--! @details
--! This file contains the testbench for the ACK_Unit entity.  
--! It tests:
--! - Enable
--! - Disable
--! - ACK sending
--! - Ignoring messages when disabled

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_ACK_Unit is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_ACK_Unit;

architecture TESTBENCH of TB_ACK_Unit is
  component ACK_Unit
    Generic (
    HOST_DATA_BITS : integer := 8;
    ACK_UNIT_NUMBER : integer := 2
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0);
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); 
    unit_data_out : out std_logic_vector(13 downto 0); 
    scheduler_wanted : out std_logic; 
    scheduler_done : in std_logic;
    error_to_host : out std_logic := '0';
    error_from_host : out std_logic := '0';
    unit_number : in std_logic_vector(5 downto 0)
  );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en : std_logic;
  signal tb_access_mode : std_logic_vector(1 downto 0); --*0: set, *1: get
  signal tb_unit_data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out : STD_LOGIC_VECTOR(13 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done : std_logic;
  signal tb_error_to_host, tb_exp_error_to_host : std_logic := '0';
  signal tb_error_from_host, tb_exp_error_from_host : std_logic := '0'; 
  signal tb_unit_number : STD_LOGIC_VECTOR (5 downto 0);

  constant tbase : time := 100 ns;
begin
  COMP: ACK_Unit generic map(8, 2) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host, tb_unit_number);

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

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 11*tbase, -- should be ignored
    '1' after 20*tbase, '0' after 21*tbase, -- enable
    '1' after 30*tbase, '0' after 31*tbase, -- random message
    '1' after 40*tbase, '0' after 41*tbase, -- disable
    '1' after 50*tbase, '0' after 51*tbase; -- should be ignored

  tb_access_mode <= "00";

  tb_unit_data_in <= "00000000",
    "11110000" after 11*tbase,
    "11111111" after 21*tbase,
    "10101010" after 31*tbase,
    "00000000" after 41*tbase,
    "11000011" after 51*tbase;

  tb_scheduler_done <= '0',
    '1' after 25*tbase, '0' after 26*tbase,
    '1' after 35*tbase, '0' after 36*tbase,
    '1' after 45*tbase, '0' after 46*tbase;

  tb_unit_number <= "000000",
    "000011" after 10*tbase,
    "000010" after 20*tbase,
    "000111" after 30*tbase,
    "000010" after 40*tbase,
    "001110" after 50*tbase;

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    "00000000000000" after 11*tbase, "00000000000000" after 15*tbase, -- ignored
    "00000011111111" after 21*tbase, "00000000000000" after 25*tbase, -- enable
    "00000010101010" after 31*tbase, "00000000000000" after 35*tbase, -- random
    "00000000000000" after 41*tbase, "00000000000000" after 45*tbase, -- disable
    "00000000000000" after 51*tbase, "00000000000000" after 55*tbase; -- ignored

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 21*tbase, '0' after 25*tbase,
    '1' after 31*tbase, '0' after 35*tbase,
    '1' after 41*tbase, '0' after 45*tbase;
  
  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0';
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';


end TESTBENCH;
