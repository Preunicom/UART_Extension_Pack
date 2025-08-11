library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_ISSI_IS61WV5128BLL_SRAM_Unit is
  Port(
    signal tb_error : out std_logic
  );
end TB_ISSI_IS61WV5128BLL_SRAM_Unit;

architecture TESTBENCH of TB_ISSI_IS61WV5128BLL_SRAM_Unit is
  component ISSI_IS61WV5128BLL_SRAM_Unit
    Generic (
      IN_FREQ : integer := 12000000;
      ACCESS_TIME_NS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      read_en : in std_logic;
      write_en : in std_logic;
      adr_in : in unsigned(18 downto 0);
      data_in : in std_logic_vector(7 downto 0);
      data_out : out std_logic_vector(7 downto 0);
      data_out_en : out std_logic;
      sram_adr : out std_logic_vector(18 downto 0);
      sram_data : inout std_logic_vector(7 downto 0);
      sram_oen : out std_logic := '1';
      sram_cen : out std_logic := '1';
      sram_wen : out std_logic := '1';
      error : out std_logic := '0'
    );
  end component;

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_read_en : std_logic;
  signal tb_write_en : std_logic;
  signal tb_adr_in : unsigned(18 downto 0);
  signal tb_data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_data_out, tb_exp_data_out : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_data_out_en, tb_exp_data_out_en : std_logic;

  signal tb_sram_adr, tb_exp_sram_adr : std_logic_vector(18 downto 0);
  signal tb_sram_data, tb_exp_sram_data, tb_sram_data_no_pullup : std_logic_vector(7 downto 0);
  signal tb_sram_oen, tb_exp_sram_oen : std_logic;
  signal tb_sram_cen, tb_exp_sram_cen : std_logic;
  signal tb_sram_wen, tb_exp_sram_wen : std_logic;
  signal tb_error_comp, tb_exp_error_comp : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: ISSI_IS61WV5128BLL_SRAM_Unit generic map(12000000, 8) port map(tb_clk, tb_rst, tb_read_en, tb_write_en, tb_adr_in, tb_data_in, tb_data_out, tb_data_out_en, tb_sram_adr, tb_sram_data, tb_sram_oen, tb_sram_cen, tb_sram_wen, tb_error_comp);

  tb_sram_data <= tb_sram_data_no_pullup when tb_sram_data_no_pullup /= "ZZZZZZZZ" else (others => 'H');

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

  tb_read_en <= '0',
    '1' after 51*tbase, '0' after 52*tbase;

  tb_write_en <= '0',
    '1' after 31*tbase, '0' after 32*tbase;

  tb_adr_in <= (others => '0'),
    "0010000111111110000" after 31*tbase, (others => '0') after 32*tbase,
    "0010000111111110000" after 51*tbase, (others => '0') after 52*tbase;

  tb_data_in <= (others => '0'),
    x"3F" after 31*tbase, (others => '0') after 32*tbase;

  tb_sram_data_no_pullup <= (others=>'Z'),
    x"3F" after 52*tbase, (others=>'Z') after 54*tbase;

  tb_exp_data_out <=  (others => 'U'), (others => '0') after 1*tbase,
    x"3F" after 53*tbase,  (others => '0') after 54*tbase;

  tb_exp_data_out_en <= 'U', '0' after 1*tbase,
    '1' after 53*tbase, '0' after 54*tbase;

  tb_exp_sram_data <= (others=>'H'),
    x"3F" after 33*tbase, (others=>'H') after 35*tbase,
    x"3F" after 52*tbase, (others=>'H') after 54*tbase;

  tb_exp_sram_adr <= (others=>'U'), (others=>'0') after 1*tbase,
    "0010000111111110000" after 31*tbase, (others=>'0') after 35*tbase, -- W
    "0010000111111110000" after 51*tbase, (others=>'0') after 54*tbase; -- R

  tb_exp_sram_cen <= '1',
    '0' after 31*tbase, '1' after 35*tbase, -- W
    '0' after 51*tbase, '1' after 54*tbase; -- R

  tb_exp_sram_oen <= '1',
    '1' after 31*tbase, '1' after 35*tbase, -- W
    '0' after 51*tbase, '1' after 54*tbase; -- R

  tb_exp_sram_wen <= '1',
    '0' after 31*tbase, '1' after 35*tbase, -- W
    '1' after 51*tbase, '1' after 54*tbase; -- R

  tb_exp_error_comp <= '0';

  tb_error <= '0' when 
    (tb_exp_data_out = tb_data_out)
    and (tb_exp_data_out_en = tb_data_out_en)
    and (tb_exp_sram_data = tb_sram_data) 
    and (tb_exp_sram_adr = tb_sram_adr) 
    and (tb_exp_sram_cen = tb_sram_cen) 
    and (tb_exp_sram_oen = tb_sram_oen) 
    and (tb_exp_sram_wen = tb_sram_wen) 
    and (tb_exp_error_comp = tb_error_comp) else '1';

end TESTBENCH;
