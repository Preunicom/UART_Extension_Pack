library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_CLK_Manager is
  Port (
    tb_error : out std_logic
  );
end TB_SPI_CLK_Manager;

architecture TESTBENCH of TB_SPI_CLK_Manager is
  component SPI_CLK_Manager
    Generic (
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0;
      AMOUNT_SLAVES : integer := 1
    );
    Port (
      clk, rst : in std_logic;
      write_en : in std_logic;
      slave_id : in integer;
      prescaled_falling_edge : in std_logic;
      prescaled_rising_edge : in std_logic;
      prescaler_rst : out std_logic;
      deserializer_clk_en : out std_logic;
      serializer_clk_en : out std_logic;
      SCK : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      ready : out std_logic := '1'
    );
  end component;
  component SPI_Prescaler
    generic (
      -- IN_FREQ_HZ has to be minimum 2*OUT_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      OUT_FREQ_HZ : integer := 9600;
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0
    );
    port (
      clk, rst      : in  STD_LOGIC;
      clk_prescaled_rising_edge : out STD_LOGIC;
      clk_prescaled_falling_edge : out STD_LOGIC
    );
  end component; 
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_write_en: std_logic;
  signal tb_slave_id : integer;
  signal tb_prescaled_falling_edge, tb_exp_prescaled_falling_edge : std_logic;
  signal tb_prescaled_rising_edge, tb_exp_prescaled_rising_edge : std_logic;
  signal tb_prescaler_rst, tb_exp_prescaler_rst : std_logic;
  signal tb_deserializer_clk_en, tb_exp_deserializer_clk_en : std_logic;
  signal tb_serializer_clk_en, tb_exp_serializer_clk_en : std_logic;
  signal tb_SCK, tb_exp_SCK : std_logic;
  signal tb_CS, tb_exp_CS : std_logic_vector(3 downto 0);
  signal tb_ready, tb_exp_ready : std_logic;
  constant tbase : time := 100 ns;
  signal presc_rst_comb : std_logic;
begin
  COMP: SPI_CLK_Manager generic map(8, 0, 4) port map(tb_clk, tb_rst, tb_write_en, tb_slave_id, tb_prescaled_falling_edge, tb_prescaled_rising_edge, tb_prescaler_rst, tb_deserializer_clk_en, tb_serializer_clk_en, tb_SCK, tb_CS, tb_ready);
  -- 5 MHz output prescaled clk
  PRESCALE: SPI_Prescaler generic map(10000000, 5000000, 8, 0) port map(tb_clk, presc_rst_comb, tb_prescaled_rising_edge, tb_prescaled_falling_edge);

  presc_rst_comb <= tb_prescaler_rst or tb_rst;

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

  tb_rst <= '1', '0' after 3*tbase;

  tb_write_en <= '0',
    '1' after 11*tbase, '0' after 12*tbase,
    '1' after 41*tbase, '0' after 42*tbase,
    '1' after 71*tbase, '0' after 72*tbase,
    '1' after 76*tbase, '0' after 91*tbase;

  tb_slave_id <= 0,
    1 after 1*tbase, 0 after 15*tbase;

  tb_exp_prescaled_falling_edge <= 'U', '0' after 1*tbase,
    '1' after 13*tbase, '0' after 14*tbase, 
    '1' after 15*tbase, '0' after 16*tbase, 
    '1' after 17*tbase, '0' after 18*tbase, 
    '1' after 19*tbase, '0' after 20*tbase, 
    '1' after 21*tbase, '0' after 22*tbase, 
    '1' after 23*tbase, '0' after 24*tbase, 
    '1' after 25*tbase, '0' after 26*tbase,
    '1' after 27*tbase, '0' after 28*tbase,
    '1' after 43*tbase, '0' after 44*tbase, 
    '1' after 45*tbase, '0' after 46*tbase, 
    '1' after 47*tbase, '0' after 48*tbase, 
    '1' after 49*tbase, '0' after 50*tbase, 
    '1' after 51*tbase, '0' after 52*tbase, 
    '1' after 53*tbase, '0' after 54*tbase,
    '1' after 55*tbase, '0' after 56*tbase,
    '1' after 57*tbase, '0' after 58*tbase,
    '1' after 73*tbase, '0' after 74*tbase,
    '1' after 75*tbase, '0' after 76*tbase,
    '1' after 77*tbase, '0' after 78*tbase,
    '1' after 79*tbase, '0' after 80*tbase,
    '1' after 81*tbase, '0' after 82*tbase,
    '1' after 83*tbase, '0' after 84*tbase,
    '1' after 85*tbase, '0' after 86*tbase,
    '1' after 87*tbase, '0' after 88*tbase,
    '1' after 92*tbase, '0' after 93*tbase,
    '1' after 94*tbase, '0' after 95*tbase,
    '1' after 96*tbase, '0' after 97*tbase,
    '1' after 98*tbase, '0' after 99*tbase,
    '1' after 100*tbase, '0' after 101*tbase,
    '1' after 102*tbase, '0' after 103*tbase,
    '1' after 104*tbase, '0' after 105*tbase,
    '1' after 106*tbase, '0' after 107*tbase;

    tb_exp_prescaled_rising_edge <= 'U', '0' after 1*tbase,
    '1' after 12*tbase, '0' after 13*tbase, 
    '1' after 14*tbase, '0' after 15*tbase, 
    '1' after 16*tbase, '0' after 17*tbase, 
    '1' after 18*tbase, '0' after 19*tbase, 
    '1' after 20*tbase, '0' after 21*tbase, 
    '1' after 22*tbase, '0' after 23*tbase, 
    '1' after 24*tbase, '0' after 25*tbase,
    '1' after 26*tbase, '0' after 27*tbase,
    '1' after 42*tbase, '0' after 43*tbase, 
    '1' after 44*tbase, '0' after 45*tbase, 
    '1' after 46*tbase, '0' after 47*tbase, 
    '1' after 48*tbase, '0' after 49*tbase, 
    '1' after 50*tbase, '0' after 51*tbase, 
    '1' after 52*tbase, '0' after 53*tbase, 
    '1' after 54*tbase, '0' after 55*tbase,
    '1' after 56*tbase, '0' after 57*tbase,
    '1' after 72*tbase, '0' after 73*tbase,
    '1' after 74*tbase, '0' after 75*tbase,
    '1' after 76*tbase, '0' after 77*tbase,
    '1' after 78*tbase, '0' after 79*tbase,
    '1' after 80*tbase, '0' after 81*tbase,
    '1' after 82*tbase, '0' after 83*tbase,
    '1' after 84*tbase, '0' after 85*tbase,
    '1' after 86*tbase, '0' after 87*tbase,
    '1' after 91*tbase, '0' after 92*tbase,
    '1' after 93*tbase, '0' after 94*tbase,
    '1' after 95*tbase, '0' after 96*tbase,
    '1' after 97*tbase, '0' after 98*tbase,
    '1' after 99*tbase, '0' after 100*tbase,
    '1' after 101*tbase, '0' after 102*tbase,
    '1' after 103*tbase, '0' after 104*tbase,
    '1' after 105*tbase, '0' after 106*tbase;

  tb_exp_prescaler_rst <= 'U' after 1*tbase,
    '1' after 1*tbase, '0' after 11*tbase,
    '1' after 29*tbase, '0' after 41*tbase,
    '1' after 59*tbase, '0' after 71*tbase,
    '1' after 89*tbase, '0' after 90*tbase,
    '1' after 108*tbase;

  tb_exp_deserializer_clk_en <= 'U', '0' after 1*tbase,
    '1' after 13*tbase, '0' after 14*tbase, 
    '1' after 15*tbase, '0' after 16*tbase, 
    '1' after 17*tbase, '0' after 18*tbase, 
    '1' after 19*tbase, '0' after 20*tbase, 
    '1' after 21*tbase, '0' after 22*tbase, 
    '1' after 23*tbase, '0' after 24*tbase, 
    '1' after 25*tbase, '0' after 26*tbase,
    '1' after 27*tbase, '0' after 28*tbase,
    '1' after 43*tbase, '0' after 44*tbase, 
    '1' after 45*tbase, '0' after 46*tbase, 
    '1' after 47*tbase, '0' after 48*tbase, 
    '1' after 49*tbase, '0' after 50*tbase, 
    '1' after 51*tbase, '0' after 52*tbase, 
    '1' after 53*tbase, '0' after 54*tbase, 
    '1' after 55*tbase, '0' after 56*tbase,
    '1' after 57*tbase, '0' after 58*tbase,
    '1' after 73*tbase, '0' after 74*tbase,
    '1' after 75*tbase, '0' after 76*tbase,
    '1' after 77*tbase, '0' after 78*tbase,
    '1' after 79*tbase, '0' after 80*tbase,
    '1' after 81*tbase, '0' after 82*tbase,
    '1' after 83*tbase, '0' after 84*tbase,
    '1' after 85*tbase, '0' after 86*tbase,
    '1' after 87*tbase, '0' after 88*tbase,
    '1' after 92*tbase, '0' after 93*tbase,
    '1' after 94*tbase, '0' after 95*tbase,
    '1' after 96*tbase, '0' after 97*tbase,
    '1' after 98*tbase, '0' after 99*tbase,
    '1' after 100*tbase, '0' after 101*tbase,
    '1' after 102*tbase, '0' after 103*tbase,
    '1' after 104*tbase, '0' after 105*tbase,
    '1' after 106*tbase, '0' after 107*tbase;

  tb_exp_serializer_clk_en <= 'U', '0' after 1*tbase,
    '1' after 12*tbase, '0' after 13*tbase, -- virtual
    '1' after 14*tbase, '0' after 15*tbase, 
    '1' after 16*tbase, '0' after 17*tbase, 
    '1' after 18*tbase, '0' after 19*tbase, 
    '1' after 20*tbase, '0' after 21*tbase, 
    '1' after 22*tbase, '0' after 23*tbase, 
    '1' after 24*tbase, '0' after 25*tbase, 
    '1' after 26*tbase, '0' after 27*tbase,
    '1' after 28*tbase, '0' after 29*tbase,
    '1' after 42*tbase, '0' after 43*tbase, -- virtual
    '1' after 44*tbase, '0' after 45*tbase, 
    '1' after 46*tbase, '0' after 47*tbase, 
    '1' after 48*tbase, '0' after 49*tbase, 
    '1' after 50*tbase, '0' after 51*tbase, 
    '1' after 52*tbase, '0' after 53*tbase, 
    '1' after 54*tbase, '0' after 55*tbase, 
    '1' after 56*tbase, '0' after 57*tbase,
    '1' after 58*tbase, '0' after 59*tbase,
    '1' after 72*tbase, '0' after 73*tbase, -- virtual
    '1' after 74*tbase, '0' after 75*tbase,
    '1' after 76*tbase, '0' after 77*tbase,
    '1' after 78*tbase, '0' after 79*tbase,
    '1' after 80*tbase, '0' after 81*tbase,
    '1' after 82*tbase, '0' after 83*tbase,
    '1' after 84*tbase, '0' after 85*tbase,
    '1' after 86*tbase, '0' after 87*tbase,
    '1' after 88*tbase, '0' after 89*tbase,
    '1' after 91*tbase, '0' after 92*tbase, -- virtual
    '1' after 93*tbase, '0' after 94*tbase,
    '1' after 95*tbase, '0' after 96*tbase,
    '1' after 97*tbase, '0' after 98*tbase,
    '1' after 99*tbase, '0' after 100*tbase,
    '1' after 101*tbase, '0' after 102*tbase,
    '1' after 103*tbase, '0' after 104*tbase,
    '1' after 105*tbase, '0' after 106*tbase,
    '1' after 107*tbase, '0' after 108*tbase;

  tb_exp_SCK <= 'U', '0' after 1*tbase,
    '1' after 14*tbase, '0' after 15*tbase, 
    '1' after 16*tbase, '0' after 17*tbase, 
    '1' after 18*tbase, '0' after 19*tbase, 
    '1' after 20*tbase, '0' after 21*tbase, 
    '1' after 22*tbase, '0' after 23*tbase, 
    '1' after 24*tbase, '0' after 25*tbase, 
    '1' after 26*tbase, '0' after 27*tbase,
    '1' after 28*tbase, '0' after 29*tbase,
    '1' after 44*tbase, '0' after 45*tbase, 
    '1' after 46*tbase, '0' after 47*tbase, 
    '1' after 48*tbase, '0' after 49*tbase, 
    '1' after 50*tbase, '0' after 51*tbase, 
    '1' after 52*tbase, '0' after 53*tbase, 
    '1' after 54*tbase, '0' after 55*tbase, 
    '1' after 56*tbase, '0' after 57*tbase,
    '1' after 58*tbase, '0' after 59*tbase,
    '1' after 74*tbase, '0' after 75*tbase,
    '1' after 76*tbase, '0' after 77*tbase,
    '1' after 78*tbase, '0' after 79*tbase,
    '1' after 80*tbase, '0' after 81*tbase,
    '1' after 82*tbase, '0' after 83*tbase,
    '1' after 84*tbase, '0' after 85*tbase,
    '1' after 86*tbase, '0' after 87*tbase,
    '1' after 88*tbase, '0' after 89*tbase,
    '1' after 93*tbase, '0' after 94*tbase,
    '1' after 95*tbase, '0' after 96*tbase,
    '1' after 97*tbase, '0' after 98*tbase,
    '1' after 99*tbase, '0' after 100*tbase,
    '1' after 101*tbase, '0' after 102*tbase,
    '1' after 103*tbase, '0' after 104*tbase,
    '1' after 105*tbase, '0' after 106*tbase,
    '1' after 107*tbase, '0' after 108*tbase;

  tb_exp_CS <= (others => '1'),
    x"D" after 12*tbase, x"F" after 30*tbase,
    x"E" after 42*tbase, x"F" after 60*tbase,
    x"E" after 72*tbase, x"F" after 90*tbase,
    x"E" after 91*tbase, x"F" after 109*tbase;

  tb_exp_ready <= '1',
    '0' after 11*tbase, '1' after 29*tbase,
    '0' after 41*tbase, '1' after 59*tbase,
    '0' after 71*tbase, '1' after 89*tbase,
    '0' after 90*tbase, '1' after 108*tbase;

  tb_error <= '0' when
    (tb_exp_deserializer_clk_en = tb_deserializer_clk_en) 
    and (tb_exp_prescaler_rst = tb_prescaler_rst) 
    and (tb_exp_serializer_clk_en = tb_serializer_clk_en) 
    and (tb_exp_prescaled_falling_edge = tb_prescaled_falling_edge) 
    and (tb_exp_prescaled_rising_edge = tb_prescaled_rising_edge) 
    and (tb_exp_SCK = tb_SCK)
    and (tb_exp_CS = tb_CS) 
    and (tb_exp_ready = tb_ready) else '1';

end TESTBENCH;
