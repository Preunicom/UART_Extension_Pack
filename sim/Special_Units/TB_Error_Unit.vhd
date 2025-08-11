library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Error_Unit is
  Port(
    signal tb_error : out std_logic
  );
end TB_Error_Unit;

architecture TESTBENCH of TB_Error_Unit is
  component Error_Unit
    Generic (
      HOST_DATA_BITS : integer := 8
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
      units_error_to_host : in std_logic_vector(63 downto 0);
      decoder_error : in std_logic;
      units_error_from_host : in std_logic_vector(63 downto 0)
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en : std_logic;
  signal tb_access_mode : std_logic_vector(1 downto 0);
  signal tb_unit_data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out : STD_LOGIC_VECTOR(13 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done : std_logic;
  signal tb_error_to_host, tb_exp_error_to_host : std_logic := '0';
  signal tb_error_from_host, tb_exp_error_from_host : std_logic := '0'; 
  signal tb_units_error_to_host : std_logic_vector(63 downto 0);
  signal tb_decoder_error : std_logic;
  signal tb_units_error_from_host : std_logic_vector(63 downto 0);

  signal suffix : std_logic_vector(13 downto 3) := (others => '0');

  constant tbase : time := 100 ns;
begin
  COMP: Error_Unit generic map(8) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host, tb_units_error_to_host, tb_decoder_error, tb_units_error_from_host);

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

  tb_write_en <= '0';

  tb_access_mode <= "00";

  tb_unit_data_in <= "UUUUUUUU", "00000000" after 1*tbase;

  tb_scheduler_done <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 22*tbase, '0' after 23*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 5*tbase, '0' after 10*tbase,
    '1' after 16*tbase, '0' after 22*tbase;

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    suffix & "001" after 5*tbase, (others => '0') after 10*tbase,
    suffix & "010" after 16*tbase,
    suffix & "110" after 18*tbase, (others => '0') after 22*tbase;

  tb_decoder_error <= '0',
    '1' after 4*tbase, '0' after 5*tbase;

  tb_units_error_to_host <= (others => '0'),
    (others => '1') after 15*tbase, (others => '0') after 16*tbase;

  tb_units_error_from_host <= (others => '0'),
    (others => '1') after 17*tbase, (others => '0') after 18*tbase;

  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0';
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end TESTBENCH;