--! @file
--! @brief Testbench for the IO_Sync_Vector
--! @details
--! This file contains the testbench for the IO_Sync_Vector entity.  
--! It tests:
--! - Normal operation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_IO_Sync_Vector is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_IO_Sync_Vector;

architecture TESTBENCH of TB_IO_Sync_Vector is
  component IO_Sync_Vector
    Generic(
      len: integer := 2
    );
    Port (
      clk : in std_logic;
      rst : in std_logic;
      async_in : in std_logic_vector(len-1 downto 0);
      sync_out : out std_logic_vector(len-1 downto 0) := (others => '0')
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_async_in : std_logic_vector(7 downto 0);
  signal tb_sync_out, tb_exp_sync_out : std_logic_vector(7 downto 0) := (others => '0');

  constant tbase : time := 100 ns;
begin
  COMP: IO_Sync_Vector generic map(8) port map(tb_clk, tb_rst, tb_async_in, tb_sync_out);

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

  tb_async_in <= (others => '0'),
    x"10" after 10*tbase,
    x"13" after 11*tbase,
    x"87" after 12*tbase,
    x"00" after 13*tbase;

  tb_exp_sync_out <= (others => '0'),
    x"10" after 11*tbase,
    x"13" after 12*tbase,
    x"87" after 13*tbase,
    x"00" after 14*tbase;

  tb_error <= '0' when
    (tb_exp_sync_out = tb_sync_out) else '1';

end TESTBENCH;