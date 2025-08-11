library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_I2C_Unit is
  Port (
    tb_error : out std_logic
  );
end TB_I2C_Unit;

architecture TESTBENCH of TB_I2C_Unit is
  component I2C_Unit
    generic(
      -- IN_FREQ_HZ has to be minimum 4*OUT_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      I2C_FREQ_HZ : integer := 100000
    );
    port(
      clk, rst : in std_logic;
      write_en : in std_logic;
      adr : in std_logic_vector(6 downto 0);
      mode_recv : in std_logic;
      send_data : in std_logic_vector(7 downto 0);
      data_saved : out std_logic;
      recv_data : out std_logic_vector(7 downto 0);
      recv_data_valid : out std_logic;
      error : out std_logic;
      SCL : inout std_logic;
      SDA : inout std_logic
    );
  end component;
  signal tb_clk : std_logic := '0';
  signal tb_rst : std_logic := '1';
  signal tb_write_en : std_logic := '0';
  signal tb_adr : std_logic_vector(6 downto 0);
  signal tb_mode_recv : std_logic := '0';
  signal tb_send_data : std_logic_vector(7 downto 0);
  signal tb_data_saved, tb_exp_data_saved : std_logic;
  signal tb_recv_data, tb_exp_recv_data : std_logic_vector(7 downto 0);
  signal tb_recv_data_valid, tb_exp_recv_data_valid : std_logic;
  signal tb_error_unit, tb_exp_error_unit : std_logic;
  signal tb_SCL, tb_exp_SCL, tb_SCL_no_pullup : std_logic;
  signal tb_SDA, tb_exp_SDA, tb_SDA_no_pullup : std_logic;
  constant tbase : time := 100 ns;
  constant tbase_scl : time := 1000 ns;

  signal SCL_en : std_logic;
  signal SCL_temp : std_logic;

begin
  COMP: I2C_Unit generic map(10000000, 1000000) port map (tb_clk, tb_rst, tb_write_en, tb_adr, tb_mode_recv, tb_send_data, tb_data_saved, tb_recv_data, tb_recv_data_valid, tb_error_unit, tb_SCL_no_pullup, tb_SDA_no_pullup);

  tb_SDA <= tb_SDA_no_pullup when tb_SDA_no_pullup /= 'Z' else 'H';
  tb_SCL <= tb_SCL_no_pullup when tb_SCL_no_pullup /= 'Z' else 'H';


  -- 10 MHz
  CLOCK: process
  begin
    for i in 2024 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  -- 1 MHz
  CLOCK_SCL: process
  begin
    SCL_temp <= '0';
    wait for 1*tbase; -- Init Prescaler because of reset
    for i in 201 downto 0 loop
      SCL_temp <= '0';
      wait for tbase_scl/2;
      SCL_temp <= '1';
      wait for tbase_scl/2;
    end loop;
    SCL_temp <= '0';
    wait;
  end process;

  SCL_en <= '0', 
    '1' after 21*tbase, '0' after 211*tbase,
    '1' after 216*tbase, '0' after 406*tbase,
    '1' after 461*tbase, '0' after 1026*tbase,
    '1' after 1211*tbase, '0' after 1396*tbase;

  tb_exp_SCL <= '0' when SCL_en = '1' and SCL_temp = '0' else 'H';

  tb_rst <= '1', '0' after 2*tbase;

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 200*tbase, '0' after 211*tbase, -- New signal (stop procedure already started)
    '1' after 450*tbase, '0' after 451*tbase,
    '1' after 460*tbase, '0' after 640*tbase, -- Repeated Start
    '1' after 650*tbase, '0' after 830*tbase, -- Repeated Start
    '1' after 1200*tbase, '0' after 1202*tbase; -- NACK

  tb_adr <= (others => '0'),
    "0000111" after 10*tbase, (others => '0') after 11*tbase,
    "0000111" after 200*tbase, (others => '0') after 211*tbase,
    "1111011" after 450*tbase, (others => '0') after 451*tbase,
    "0000001" after 460*tbase, (others => '0') after 640*tbase,
    "0000001" after 650*tbase, (others => '0') after 830*tbase,
    "0000001" after 1200*tbase, (others => '0') after 1202*tbase;

  tb_mode_recv <= '0',
    '0' after 10*tbase, '0' after 11*tbase,
    '1' after 200*tbase, '0' after 211*tbase,
    '0' after 450*tbase, '0' after 451*tbase,
    '0' after 460*tbase, '0' after 640*tbase,
    '1' after 650*tbase, '0' after 830*tbase,
    '0' after 1200*tbase, '0' after 1202*tbase;

  tb_send_data <= (others => '0'),
    "01100110" after 10*tbase, (others => '0') after 11*tbase,
    "11111111" after 200*tbase, (others => '0') after 211*tbase, -- Unused (recv mode)
    "01010101" after 450*tbase, (others => '0') after 451*tbase,
    "11110000" after 460*tbase, (others => '0') after 640*tbase,
    "11111111" after 650*tbase, (others => '0') after 830*tbase, -- Unused (recv mode)
    "11111111" after 1200*tbase, (others => '0') after 1202*tbase;

  tb_SDA_no_pullup <= 'Z',
    '0' after 104*tbase, 'Z' after 114*tbase,
    '0' after 194*tbase, 'Z' after 204*tbase,
    '0' after 302*tbase, 'Z' after 312*tbase,
    '1' after 316*tbase, '0' after 326*tbase, '0' after 336*tbase, '0' after 346*tbase, '0' after 356*tbase, '0' after 366*tbase, '0' after 376*tbase, '1' after 386*tbase, 'Z' after 391*tbase,
    '0' after 544*tbase, 'Z' after 554*tbase,
    '0' after 634*tbase, 'Z' after 644*tbase,
    '0' after 734*tbase, 'Z' after 744*tbase,
    '0' after 824*tbase, 'Z' after 834*tbase,
    '0' after 924*tbase, 'Z' after 934*tbase,
    '1' after 936*tbase, '0' after 945*tbase, '1' after 955*tbase, '0' after 965*tbase, '1' after 975*tbase, '0' after 985*tbase, '1' after 995*tbase, '1' after 1005*tbase, 'Z' after 1010*tbase,
    '1' after 1384*tbase, 'Z' after 1394*tbase; -- NACK

  tb_exp_data_saved <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 210*tbase, '0' after 211*tbase,
    '1' after 450*tbase, '0' after 451*tbase,
    '1' after 639*tbase, '0' after 640*tbase,
    '1' after 829*tbase, '0' after 830*tbase,
    '1' after 1200*tbase, '0' after 1201*tbase;

  tb_exp_recv_data <= x"FF",
    x"81" after 390*tbase,
    x"AB" after 1010*tbase;

  tb_exp_recv_data_valid <= '0',
    '1' after 390*tbase, '0' after 395*tbase,
    '1' after 1010*tbase, '0' after 1015*tbase;

  tb_exp_error_unit <= '0',
    '1' after 1390*tbase, '0' after 1391*tbase;

  tb_exp_SDA <= 'H',
    '0' after 19*tbase, 'H' after 64*tbase,
    '0' after 94*tbase, 'H' after 124*tbase,
    '0' after 144*tbase, 'H' after 164*tbase,
    '0' after 184*tbase, 'H' after 209*tbase,
    '0' after 219*tbase, 'H' after 264*tbase,
    '0' after 302*tbase, 'H' after 312*tbase, '1' after 316*tbase,
    '0' after 326*tbase, '1' after 386*tbase, 'H' after 391*tbase,
    '0' after 404*tbase, 'H' after 409*tbase,
    '0' after 459*tbase, 'H' after 464*tbase,
    '0' after 504*tbase, 'H' after 514*tbase,
    '0' after 534*tbase, 'H' after 564*tbase,
    '0' after 574*tbase, 'H' after 584*tbase,
    '0' after 594*tbase, 'H' after 604*tbase,
    '0' after 614*tbase, 'H' after 624*tbase,
    '0' after 634*tbase, 'H' after 644*tbase,
    '0' after 649*tbase, 'H' after 714*tbase,
    '0' after 724*tbase, 'H' after 744*tbase,
    '0' after 784*tbase, 'H' after 834*tbase,
    '0' after 839*tbase, 'H' after 904*tbase,
    '0' after 924*tbase, 'H' after 934*tbase, '1' after 936*tbase,
    '0' after 945*tbase, '1' after 955*tbase,
    '0' after 965*tbase, '1' after 975*tbase,
    '0' after 985*tbase, '1' after 995*tbase, 'H' after 1010*tbase,
    '0' after 1024*tbase, 'H' after 1029*tbase,
    '0' after 1209*tbase, 'H' after 1274*tbase,
    '0' after 1284*tbase, 'H' after 1294*tbase, '1' after 1384*tbase,
    '0' after 1394*tbase, 'H' after 1399*tbase;

    tb_error <= '0' when
    (tb_exp_data_saved = tb_data_saved)
    and (tb_exp_error_unit = tb_error_unit)
    and (tb_exp_recv_data = tb_recv_data)
    and (tb_exp_recv_data_valid = tb_recv_data_valid)
    and (tb_exp_SCL = tb_SCL)
    and (tb_exp_SDA = tb_SDA) else '1';

end TESTBENCH;
