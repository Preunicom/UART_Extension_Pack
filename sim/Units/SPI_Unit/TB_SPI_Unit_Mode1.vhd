--! @file
--! @brief Testbench for the SPI_Unit with SPI mode 1
--! @details
--! This file contains the testbench for the SPI_Unit entity with SPI mode 1.
--! It tests:
--! - Normal operation in SPI mode 1

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_Unit_Mode1 is
  Port (
    tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_SPI_Unit_Mode1;

architecture TESTBENCH of TB_SPI_Unit_Mode1 is
  component SPI_Unit
    Generic (
      -- IN_FREQ_HZ has to be minimum 2*SPI_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      SPI_FREQ_HZ : integer := 9600;
      AMOUNT_SLAVES : integer := 1;
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0;
      LEAST_SIG_BIT_FIRST : integer := 0 -- true or false
    );
    Port ( 
      clk, rst : in std_logic;
      SCK : out std_logic;
      send_data : in std_logic_vector(DATA_BITS-1 downto 0);
      slave_id : in integer;
      write_en : in std_logic;
      ready : out std_logic;
      MOSI : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      received_data : out std_logic_vector(DATA_BITS-1 downto 0);
      new_data_received : out std_logic;
      MISO : in std_logic
    );
  end component;
  signal tb_clk, tb_rst : std_logic;
  signal tb_SCK, tb_exp_SCK : std_logic;
  signal tb_send_data : std_logic_vector(7 downto 0);
  signal tb_slave_id : integer;
  signal tb_write_en : std_logic;
  signal tb_ready, tb_exp_ready : std_logic;
  signal tb_MOSI, tb_exp_MOSI : std_logic;
  signal tb_CS, tb_exp_CS : std_logic_vector(1 downto 0) := (others => '1');
  signal tb_received_data, tb_exp_received_data : std_logic_vector(7 downto 0);
  signal tb_new_data_received, tb_exp_new_data_received : std_logic;
  signal tb_MISO : std_logic;
  constant tbase : time := 100 ns;
begin
  COMP: SPI_Unit generic map(10000000, 5000000, 2, 8, 1, 0) port map(tb_clk, tb_rst, tb_SCK, tb_send_data, tb_slave_id, tb_write_en, tb_ready, tb_MOSI, tb_CS, tb_received_data, tb_new_data_received, tb_MISO);

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

  tb_send_data <= (others => '0'),
    "11001010" after 9*tbase, (others => '0') after 10*tbase, -- 0xCA
    "10001011" after 29*tbase, (others => '0') after 30*tbase, -- 0x8B
    "00000001" after 49*tbase, (others => '0') after 50*tbase; -- 0x01

  tb_slave_id <= 0,
    1 after 9*tbase, 0 after 10*tbase,
    0 after 29*tbase, 0 after 30*tbase,
    1 after 49*tbase, 0 after 50*tbase;

  tb_write_en <= '0',
    '1' after 9*tbase, '0' after 10*tbase,
    '1' after 29*tbase, '0' after 30*tbase,
    '1' after 49*tbase, '0' after 50*tbase;

  tb_MISO <= '0',
    '1' after 12*tbase, '1' after 14*tbase, '1' after 16*tbase, '1' after 18*tbase, '0' after 20*tbase, '0' after 22*tbase, '0' after 24*tbase, '0' after 26*tbase, --0xF0
    '1' after 32*tbase, '0' after 34*tbase, '1' after 36*tbase, '0' after 38*tbase, '0' after 40*tbase, '1' after 42*tbase, '0' after 44*tbase, '1' after 46*tbase, --0xA5
    '0' after 52*tbase, '0' after 54*tbase, '1' after 56*tbase, '1' after 58*tbase, '0' after 60*tbase, '0' after 62*tbase, '0' after 64*tbase, '0' after 66*tbase; --0x30

  tb_exp_SCK <= 'U', '0' after 1*tbase,
    '1' after 12*tbase, '0' after 13*tbase, 
    '1' after 14*tbase, '0' after 15*tbase, 
    '1' after 16*tbase, '0' after 17*tbase, 
    '1' after 18*tbase, '0' after 19*tbase, 
    '1' after 20*tbase, '0' after 21*tbase, 
    '1' after 22*tbase, '0' after 23*tbase, 
    '1' after 24*tbase, '0' after 25*tbase, 
    '1' after 26*tbase, '0' after 27*tbase, -- EDN PCK 1
    '1' after 32*tbase, '0' after 33*tbase, 
    '1' after 34*tbase, '0' after 35*tbase, 
    '1' after 36*tbase, '0' after 37*tbase, 
    '1' after 38*tbase, '0' after 39*tbase, 
    '1' after 40*tbase, '0' after 41*tbase, 
    '1' after 42*tbase, '0' after 43*tbase, 
    '1' after 44*tbase, '0' after 45*tbase, 
    '1' after 46*tbase, '0' after 47*tbase, -- EDN PCK 2
    '1' after 52*tbase, '0' after 53*tbase, 
    '1' after 54*tbase, '0' after 55*tbase, 
    '1' after 56*tbase, '0' after 57*tbase, 
    '1' after 58*tbase, '0' after 59*tbase, 
    '1' after 60*tbase, '0' after 61*tbase, 
    '1' after 62*tbase, '0' after 63*tbase, 
    '1' after 64*tbase, '0' after 65*tbase,
    '1' after 66*tbase, '0' after 67*tbase; -- EDN PCK 3

  tb_exp_ready <= '1',
    '0' after 9*tbase, '1' after 27*tbase,
    '0' after 29*tbase, '1' after 47*tbase,
    '0' after 49*tbase, '1' after 67*tbase;

  tb_exp_MOSI <= '0',
    '1' after 12*tbase, '1' after 14*tbase, '0' after 16*tbase, '0' after 18*tbase, '1' after 20*tbase, '0' after 22*tbase, '1' after 24*tbase, '0' after 26*tbase, --0xCA
    '1' after 32*tbase, '0' after 34*tbase, '0' after 36*tbase, '0' after 38*tbase, '1' after 40*tbase, '0' after 42*tbase, '1' after 44*tbase, '1' after 46*tbase, '0' after 48*tbase, --0x8B
    '0' after 52*tbase, '0' after 54*tbase, '0' after 56*tbase, '0' after 58*tbase, '0' after 60*tbase, '0' after 62*tbase, '0' after 64*tbase, '1' after 66*tbase, '0' after 68*tbase; --0x01

  tb_exp_CS <= "11",
    "01" after 10*tbase, "11" after 28*tbase,
    "10" after 30*tbase, "11" after 48*tbase,
    "01" after 50*tbase, "11" after 68*tbase;

  tb_exp_received_data <= (others => 'U'),  (others => '0') after 1*tbase,
    x"F0" after 28*tbase,
    x"A5" after 48*tbase,
    x"30" after 68*tbase;

  tb_exp_new_data_received <= 'U', '0' after 1*tbase,
    '1' after 28*tbase, '0' after 34*tbase,
    '1' after 48*tbase, '0' after 54*tbase,
    '1' after 68*tbase;

  tb_error <= '0' when
    (tb_exp_SCK = tb_SCK)
    and (tb_ready = tb_exp_ready)
    and (tb_MOSI = tb_exp_MOSI)
    and (tb_CS = tb_exp_CS)
    and (tb_received_data = tb_exp_received_data)
    and (tb_new_data_received = tb_exp_new_data_received) else '1';

end TESTBENCH;