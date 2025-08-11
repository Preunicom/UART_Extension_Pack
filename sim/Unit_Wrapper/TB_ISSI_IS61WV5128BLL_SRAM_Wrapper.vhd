library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity TB_ISSI_IS61WV5128BLL_SRAM_Wrapper is
  Port(
    signal tb_error : out std_logic
  );
end TB_ISSI_IS61WV5128BLL_SRAM_Wrapper;

architecture TESTBENCH of TB_ISSI_IS61WV5128BLL_SRAM_Wrapper is
  component ISSI_IS61WV5128BLL_SRAM_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      IN_FREQ : integer := 12000000;
      ACCESS_TIME_NS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0);
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0) := (others => '0');
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      sram_adr : out std_logic_vector(18 downto 0);
      sram_data : inout std_logic_vector(7 downto 0);
      sram_oen : out std_logic := '1';
      sram_cen : out std_logic := '1';
      sram_wen : out std_logic := '1'
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

  signal tb_sram_adr, tb_exp_sram_adr : std_logic_vector(18 downto 0);
  signal tb_sram_data, tb_exp_sram_data, tb_sram_data_no_pullup : std_logic_vector(7 downto 0);
  signal tb_sram_oen, tb_exp_sram_oen : std_logic;
  signal tb_sram_cen, tb_exp_sram_cen : std_logic;
  signal tb_sram_wen, tb_exp_sram_wen : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: ISSI_IS61WV5128BLL_SRAM_Wrapper generic map(8, 12000000, 8) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host, tb_sram_adr, tb_sram_data_no_pullup, tb_sram_oen, tb_sram_cen, tb_sram_wen);

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

  tb_write_en <= '0',
    '1' after 3*tbase, '0' after 4*tbase,
    '1' after 6*tbase, '0' after 7*tbase,
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 15*tbase, '0' after 16*tbase,
    '1' after 20*tbase, '0' after 21*tbase,
    '1' after 30*tbase, '0' after 31*tbase,
    '1' after 50*tbase, '0' after 51*tbase,
    '1' after 110*tbase, '0' after 111*tbase,
    '1' after 115*tbase, '0' after 116*tbase,
    '1' after 120*tbase, '0' after 121*tbase,
    '1' after 130*tbase, '0' after 131*tbase;

  tb_access_mode <= "00",
    "01" after 3*tbase, "00" after 4*tbase, -- Set adr (part 1)
    "00" after 6*tbase, "00" after 7*tbase, -- Reset adr.
    "01" after 10*tbase, "00" after 11*tbase, -- Set adr (part 1)
    "01" after 15*tbase, "00" after 16*tbase, -- Set adr (part 2)
    "01" after 20*tbase, "00" after 21*tbase, -- Set adr (part 3)
    "11" after 30*tbase, "00" after 31*tbase, -- Write data
    "10" after 50*tbase, "00" after 51*tbase, -- Read data
    "01" after 110*tbase, "00" after 111*tbase, -- Set adr (part 1)
    "01" after 115*tbase, "00" after 116*tbase, -- Set adr (part 2)
    "01" after 120*tbase, "00" after 121*tbase, -- Set adr (part 3)
    "01" after 130*tbase, "00" after 131*tbase; -- Set adr (part 4) (ERROR)

  tb_unit_data_in <= "00000000",
    x"AB" after 3*tbase, x"00" after 4*tbase, -- Set adr to 0xAB
    x"0F" after 6*tbase, x"00" after 7*tbase, -- Reset adr
    x"F0" after 10*tbase, x"00" after 11*tbase, -- Set adr to 0xF0
    x"0F" after 15*tbase, x"00" after 16*tbase, -- Set adr to 0x0FF0
    x"01" after 20*tbase, x"00" after 21*tbase, -- Set adr to 0x10FF0
    x"3F" after 30*tbase, x"00" after 31*tbase, -- Write data 0x3F
    x"00" after 50*tbase, x"00" after 51*tbase, -- Read data
    x"F0" after 110*tbase, x"00" after 111*tbase, -- Set adr to 0xF0
    x"0F" after 115*tbase, x"00" after 116*tbase, -- Set adr to 0x0FF0
    x"01" after 120*tbase, x"00" after 121*tbase, -- Set adr to 0x10FF0
    x"0F" after 130*tbase, x"00" after 131*tbase; -- Set adr to ERROR

  tb_scheduler_done <= '0',
    '1' after 70*tbase, '0' after 71*tbase;

  tb_sram_data_no_pullup <= (others=>'Z'),
    x"3F" after 52*tbase, (others=>'Z') after 54*tbase;

  tb_exp_unit_data_out <= (others => '0'),
    "00000000111111" after 54*tbase,  (others => '0') after 70*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 54*tbase, '0' after 70*tbase;
  
  tb_exp_error_to_host <= '0';
    
  tb_exp_error_from_host <= 'U', '0' after 1*tbase,
    '1' after 130*tbase, '0' after 131*tbase; -- Invalid adr. set

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
  
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_sram_data = tb_sram_data) 
    and (tb_exp_sram_adr = tb_sram_adr) 
    and (tb_exp_sram_cen = tb_sram_cen) 
    and (tb_exp_sram_oen = tb_sram_oen) 
    and (tb_exp_sram_wen = tb_sram_wen) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';
  
end TESTBENCH;