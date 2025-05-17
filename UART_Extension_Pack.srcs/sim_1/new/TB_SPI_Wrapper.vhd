library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_Wrapper is
  Port(
    signal tb_error : out std_logic
  );
end TB_SPI_Wrapper;

architecture TESTBENCH of TB_SPI_Wrapper is
  component SPI_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN_FREQ_HZ has to be minimum 2*SPI_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      SPI_FREQ_HZ : integer := 9600;
      AMOUNT_SLAVES : integer := 1;
      SPI_MODE : integer := 0;
      LEAST_SIG_BIT_FIRST : integer := 0; -- true or false
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); -- unused
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      SCK : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      MOSI : out std_logic;
      MISO : in std_logic
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
  signal tb_SCK, tb_exp_SCK : std_logic;
  signal tb_CS, tb_exp_CS : std_logic_vector(2 downto 0) := (others => '1');
  signal tb_MOSI, tb_exp_MOSI : std_logic;
  signal tb_MISO : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: SPI_Wrapper generic map(8, 10000000, 5000000, 3, 0, 0) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host, tb_SCK, tb_CS, tb_MOSI, tb_MISO);

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
    '1' after 9*tbase, '0' after 10*tbase,
    '1' after 14*tbase, '0' after 15*tbase,
    '1' after 19*tbase, '0' after 20*tbase,
    '1' after 34*tbase, '0' after 35*tbase,
    '1' after 44*tbase, '0' after 45*tbase,
    '1' after 69*tbase, '0' after 70*tbase,
    '1' after 90*tbase, '0' after 91*tbase;

  tb_access_mode <= "00",
    "01" after 14*tbase,
    "01" after 19*tbase,
    "00" after 34*tbase;

  tb_unit_data_in <= "00000000",
    "11000011" after 9*tbase, -- 0xC3
    "00000100" after 14*tbase, -- Slave ID (invalid, ID too big)
    "00000010" after 19*tbase, -- Slave ID
    "00001111" after 34*tbase, -- 0x0F
    "00010001" after 44*tbase, -- 0x11 (invalid, SPI Unit not ready)
    "00010001" after 69*tbase, -- 0x11
    "00100011" after 90*tbase; -- 0x23

  tb_scheduler_done <= '0',
    '1' after 39*tbase, '0' after 40*tbase,
    '1' after 59*tbase, '0' after 60*tbase,
    '1' after 119*tbase, '0' after 120*tbase; -- Error because SPI package got overwritten

  tb_MISO <= '0',
    '0' after 93*tbase, '0' after 95*tbase, '1' after 97*tbase, '1' after 99*tbase, '0' after 101*tbase, '0' after 103*tbase, '0' after 105*tbase, '0' after 107*tbase; --0x30

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    "00000000110000" after 110*tbase, (others => '0') after 119*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 29*tbase, '0' after 39*tbase,
    '1' after 54*tbase, '0' after 59*tbase,
    '1' after 89*tbase, '0' after 119*tbase;

  tb_exp_error_to_host <= '0',
    '1' after 110*tbase, '0' after 111*tbase;

  tb_exp_error_from_host <= '0',
    '1' after 14*tbase, '0' after 15*tbase,
    '1' after 44*tbase, '0' after 45*tbase;
 
  tb_exp_CS <= "111",
    "110" after 11*tbase,
    "111" after 29*tbase,
    "011" after 36*tbase,
    "111" after 54*tbase,
    "011" after 71*tbase,
    "111" after 89*tbase,
    "011" after 92*tbase,
    "111" after 110*tbase;

  tb_exp_MOSI <= '0',
    '1' after 12*tbase, '0' after 16*tbase,
    '1' after 24*tbase, '0' after 28*tbase,
    '1' after 45*tbase, '0' after 53*tbase,
    '1' after 78*tbase, '0' after 80*tbase,
    '1' after 86*tbase, '0' after 88*tbase,
    '1' after 97*tbase, '0' after 99*tbase,
    '1' after 105*tbase, '0' after 109*tbase;

  tb_exp_SCK <= 'U', '0' after 1*tbase,
    '1' after 13*tbase, '0' after 14*tbase, 
    '1' after 15*tbase, '0' after 16*tbase, 
    '1' after 17*tbase, '0' after 18*tbase, 
    '1' after 19*tbase, '0' after 20*tbase, 
    '1' after 21*tbase, '0' after 22*tbase, 
    '1' after 23*tbase, '0' after 24*tbase, 
    '1' after 25*tbase, '0' after 26*tbase, 
    '1' after 27*tbase, '0' after 28*tbase, -- END pkg 1
    '1' after 38*tbase, '0' after 39*tbase, 
    '1' after 40*tbase, '0' after 41*tbase, 
    '1' after 42*tbase, '0' after 43*tbase, 
    '1' after 44*tbase, '0' after 45*tbase, 
    '1' after 46*tbase, '0' after 47*tbase, 
    '1' after 48*tbase, '0' after 49*tbase, 
    '1' after 50*tbase, '0' after 51*tbase, 
    '1' after 52*tbase, '0' after 53*tbase, -- END pkg 2
    '1' after 73*tbase, '0' after 74*tbase,
    '1' after 75*tbase, '0' after 76*tbase,
    '1' after 77*tbase, '0' after 78*tbase,
    '1' after 79*tbase, '0' after 80*tbase,
    '1' after 81*tbase, '0' after 82*tbase,
    '1' after 83*tbase, '0' after 84*tbase,
    '1' after 85*tbase, '0' after 86*tbase,
    '1' after 87*tbase, '0' after 88*tbase, -- END pkg 3
    '1' after 94*tbase, '0' after 95*tbase,
    '1' after 96*tbase, '0' after 97*tbase,
    '1' after 98*tbase, '0' after 99*tbase,
    '1' after 100*tbase, '0' after 101*tbase,
    '1' after 102*tbase, '0' after 103*tbase,
    '1' after 104*tbase, '0' after 105*tbase,
    '1' after 106*tbase, '0' after 107*tbase,
    '1' after 108*tbase, '0' after 109*tbase; -- END pkg 4

  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_CS = tb_CS) 
    and (tb_exp_MOSI = tb_MOSI) 
    and (tb_exp_SCK = tb_SCK) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end TESTBENCH;
