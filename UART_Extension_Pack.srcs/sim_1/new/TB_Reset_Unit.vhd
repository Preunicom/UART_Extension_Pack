library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Reset_Unit is
  Port(
    signal tb_error : out std_logic
  );
end TB_Reset_Unit;

architecture Behavioral of TB_Reset_Unit is
  component Reset_Unit
    Generic (
      HOST_DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); -- unused
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); 
      unit_data_out : out std_logic_vector(13 downto 0); 
      scheduler_wanted : out std_logic; 
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0'; -- unused
      error_from_host : out std_logic := '0'; -- unused
      rst_ext_pack : out std_logic := '0'
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
  signal tb_rst_ext_pack, tb_exp_rst_ext_pack : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: Reset_Unit generic map(8) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host, tb_rst_ext_pack);

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

  tb_rst <= '1', '0' after 2*tbase, '1' after 25*tbase, '0' after 26*tbase;

  tb_write_en <= '0',
    '1' after 20*tbase, '0' after 21*tbase;

  tb_access_mode <= "00";

  tb_unit_data_in <= "UUUUUUUU", "00000000" after 1*tbase,
    "11111111" after 20*tbase,
    "00000000" after 30*tbase;

  tb_scheduler_done <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 35*tbase, '0' after 36*tbase;

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    (others => '1') after 2*tbase, (others => '0') after 10*tbase,
    (others => '1') after 26*tbase, (others => '0') after 35*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 2*tbase, '0' after 10*tbase,
    '1' after 26*tbase, '0' after 35*tbase;

  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0';

  tb_exp_rst_ext_pack <= '0',
    '1' after 20*tbase, '0' after 21*tbase;
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_rst_ext_pack = tb_rst_ext_pack) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end Behavioral;
