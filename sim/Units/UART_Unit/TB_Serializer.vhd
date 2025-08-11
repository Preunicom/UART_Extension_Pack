library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Serializer is
  Port (
    tb_error : out std_logic
  );
end TB_Serializer;

architecture TESTBENCH of TB_Serializer is
  component Serializer
    Generic(
      -- DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, clk_en_prescaled, rst, write_enable : in std_logic;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      serial_out : out std_logic;
      buffer_data_saved : out std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_clk_en_prescaled : std_logic;
  signal tb_rst : STD_LOGIC;
  signal tb_write_enable : std_logic;
  signal tb_parallel_in : std_logic_vector(7 downto 0);
  signal tb_serial_out, tb_exp_serial_out : std_logic;
  signal tb_buffer_data_saved, tb_exp_buffer_data_saved : std_logic;
  constant tbase : time := 100 ns;
begin
    COMP: Serializer generic map(8, 1, 1, 0) port map(tb_clk, tb_clk_en_prescaled, tb_rst, tb_write_enable, tb_parallel_in, tb_serial_out, tb_buffer_data_saved);

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

  tb_clk_en_prescaled <= '1';

  tb_rst <= '1', '0' after 2*tbase;

  tb_write_enable <= '0',
    '1' after 20*tbase, '0' after 21*tbase,
    '1' after 25*tbase, '0' after 32*tbase;

  tb_parallel_in <= "00000000",
    "11110000" after 20*tbase,
    "10000011" after 25*tbase;

  tb_exp_serial_out <= 'U', '1' after 1*tbase,
    '0' after 21*tbase, '0' after 22*tbase, '0' after 23*tbase, '0' after 24*tbase, '0' after 25*tbase, '1' after 26*tbase, '1' after 27*tbase, '1' after 28*tbase, '1' after 29*tbase, '0' after 30*tbase, '1' after 31*tbase, -- (0xF0)
    '0' after 32*tbase, '1' after 33*tbase, '1' after 34*tbase, '0' after 35*tbase, '0' after 36*tbase, '0' after 37*tbase, '0' after 38*tbase, '0' after 39*tbase, '1' after 40*tbase, '1' after 41*tbase, '1' after 42*tbase; -- (0x83)

  tb_exp_buffer_data_saved <= 'U', '0' after 1*tbase,
    '1' after 20*tbase, '0' after 21*tbase,
    '1' after 31*tbase, '0' after 32*tbase;

  tb_error <= '0' when
    (tb_exp_buffer_data_saved = tb_buffer_data_saved) 
    and (tb_exp_serial_out = tb_serial_out) else '1';

end TESTBENCH;
