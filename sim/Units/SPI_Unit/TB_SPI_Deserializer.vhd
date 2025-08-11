library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_Deserializer is
  Port (
    tb_error : out std_logic
  );
end TB_SPI_Deserializer;

architecture TESTBENCH of TB_SPI_Deserializer is
  component SPI_Deserializer
    Generic(
      DATA_BITS : integer := 8;
      LSB : integer := 0
    );
    Port ( 
      clk, clk_en_prescaled, rst : in std_logic;
      serial_in : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      data_valid : out std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_clk_en_prescaled : std_logic;
  signal tb_rst : STD_LOGIC;
  signal tb_serial_in : std_logic;
  signal tb_parallel_out, tb_exp_parallel_out : std_logic_vector(7 downto 0);
  signal tb_data_valid, tb_exp_data_valid : std_logic;
  constant tbase : time := 100 ns;
  constant tbase_half : time := 50 ns;
begin
  COMP: SPI_Deserializer generic map(8, 1) port map(tb_clk, tb_clk_en_prescaled, tb_rst, tb_serial_in, tb_parallel_out, tb_data_valid);

   -- 20 MHz
  CLOCK: process
  begin
    for i in 1000 downto 0 loop
      tb_clk <= '1';
      wait for tbase_half/2;
      tb_clk <= '0';
      wait for tbase_half/2;
    end loop;
    wait;
  end process;

  -- 10 MHz
  CLOCK_EN: process
  begin
    tb_clk_en_prescaled <= '0';
    wait for 20.5*tbase;
    for i in 27 downto 20 loop
      tb_clk_en_prescaled <= '1';
      wait for tbase/2;
      tb_clk_en_prescaled <= '0';
      wait for tbase/2;
    end loop;
    wait for 1*tbase;
    for i in 36 downto 29 loop
      tb_clk_en_prescaled <= '1';
      wait for tbase/2;
      tb_clk_en_prescaled <= '0';
      wait for tbase/2;
    end loop;
    wait for 3*tbase;
    for i in 47 downto 40 loop
      tb_clk_en_prescaled <= '1';
      wait for tbase/2;
      tb_clk_en_prescaled <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_serial_in <= '0',
    '0' after 20*tbase, '0' after 21*tbase, '0' after 22*tbase, '0' after 23*tbase, '1' after 24*tbase, '1' after 25*tbase, '1' after 26*tbase, '1' after 27*tbase, '0' after 28*tbase, -- (0xF0)
    '1' after 29*tbase, '1' after 30*tbase, '0' after 31*tbase, '0' after 32*tbase, '0' after 33*tbase, '0' after 34*tbase, '0' after 35*tbase, '1' after 36*tbase, '0' after 37*tbase, -- (0x83)
    '1' after 40*tbase, '0' after 41*tbase, '0' after 42*tbase, '0' after 43*tbase, '1' after 44*tbase, '0' after 45*tbase, '0' after 46*tbase, '1' after 47*tbase, '0' after 48*tbase; -- (0x91)

  tb_exp_parallel_out <= (others => 'U'), (others => '0') after 1*tbase_half,
    x"80" after 24.5*tbase, 
    x"C0" after 25.5*tbase, 
    x"E0" after 26.5*tbase, 
    x"F0" after 27.5*tbase, -- valid
    x"F8" after 29.5*tbase,
    x"FC" after 30.5*tbase,
    x"7E" after 31.5*tbase,
    x"3F" after 32.5*tbase,
    x"1F" after 33.5*tbase,
    x"0F" after 34.5*tbase,
    x"07" after 35.5*tbase,
    x"83" after 36.5*tbase, -- valid
    x"C1" after 40.5*tbase,
    x"60" after 41.5*tbase,
    x"30" after 42.5*tbase,
    x"18" after 43.5*tbase,
    x"8C" after 44.5*tbase,
    x"46" after 45.5*tbase,
    x"23" after 46.5*tbase,
    x"91" after 47.5*tbase; -- valid

  tb_exp_data_valid <= 'U', '0' after 1*tbase_half,
    '1' after 27.5*tbase, '0' after 29.5*tbase,
    '1' after 36.5*tbase, '0' after 40.5*tbase,
    '1' after 47.5*tbase;

  tb_error <= '0' when
    (tb_exp_parallel_out = tb_parallel_out) 
    and (tb_exp_data_valid = tb_data_valid) else '1';

end TESTBENCH;
