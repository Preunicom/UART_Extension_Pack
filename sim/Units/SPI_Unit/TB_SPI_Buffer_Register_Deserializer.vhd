--! @file
--! @brief Testbench for the SPI_Buffer_Register_Deserializer
--! @details
--! This file contains the testbench for the SPI_Buffer_Register_Deserializer entity.
--! It tests:
--! - Normal operation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_SPI_Buffer_Register_Deserializer is
  Port (
    tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_SPI_Buffer_Register_Deserializer;

architecture TESTBENCH of TB_SPI_Buffer_Register_Deserializer is
  component SPI_Buffer_Register_Deserializer 
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      write_en : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      new_data : out std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_parallel_in : std_logic_vector(7 downto 0);
  signal tb_write_en : std_logic;
  signal tb_parallel_out, tb_exp_parallel_out : std_logic_vector(7 downto 0);
  signal tb_new_data, tb_exp_new_data : std_logic;
  constant tbase : time := 100 ns;
begin
  COMP: SPI_Buffer_Register_Deserializer generic map(8) port map(tb_clk, tb_rst, tb_parallel_in, tb_write_en, tb_parallel_out, tb_new_data); 

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

  tb_parallel_in <= x"00",
    x"F0" after 27.5*tbase, (others => '0') after 29.5*tbase,
    x"83" after 36.5*tbase, (others => '0') after 40.5*tbase,
    x"91" after 47.5*tbase;

  tb_write_en <= '0',
    '1' after 27.5*tbase, '0' after 29.5*tbase,
    '1' after 36.5*tbase, '0' after 40.5*tbase,
    '1' after 47.5*tbase;

  tb_exp_parallel_out <= (others => 'U'), x"00" after 1*tbase,
    x"F0" after 28*tbase,
    x"83" after 37*tbase,
    x"91" after 48*tbase;

  tb_exp_new_data <= 'U', '0' after 1*tbase,
    '1' after 28*tbase, '0' after 30*tbase,
    '1' after 37*tbase, '0' after 41*tbase,
    '1' after 48*tbase;

  tb_error <= '0' when
    (tb_parallel_out = tb_exp_parallel_out) 
    and (tb_new_data = tb_exp_new_data) else '1';

end TESTBENCH;
