library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Buffer_Register_Serializer is
  Port (
    tb_error : out std_logic
  );
end TB_Buffer_Register_Serializer;

architecture TESTBENCH of TB_Buffer_Register_Serializer is
component Buffer_Register_Serializer
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst, write_enable : in std_logic;
      data_in : in std_logic_vector(DATA_BITS-1 downto 0);
      data_not_needed_anymore : in std_logic;
      data_out : out std_logic_vector(DATA_BITS-1 downto 0);
      full : out std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_write_enable : std_logic;
  signal tb_data_in : std_logic_vector(7 downto 0);
  signal tb_data_not_needed_anymore : std_logic;
  signal tb_data_out, tb_exp_data_out : std_logic_vector(7 downto 0);
  signal tb_full, tb_exp_full : std_logic;
  constant tbase : time := 100 ns;
begin
    COMP: Buffer_Register_Serializer generic map(8) port map(tb_clk, tb_rst, tb_write_enable, tb_data_in, tb_data_not_needed_anymore, tb_data_out, tb_full);

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

  tb_write_enable <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 21*tbase, '0' after 22*tbase,
    '1' after 25*tbase, '0' after 26*tbase,
    '1' after 30*tbase, '0' after 31*tbase;

  tb_data_in <= "00000000",
    "01110011" after 10*tbase, "00000000" after 11*tbase,
    "01100011" after 21*tbase, "00000000" after 22*tbase, 
    "01000011" after 25*tbase, "00000000" after 26*tbase, -- will not be sent
    "11110000" after 30*tbase, "00000000" after 31*tbase;

  tb_data_not_needed_anymore <= 'U', '0' after 1*tbase,
    '1' after 18*tbase, '0' after 19*tbase,
    '1' after 30*tbase, '0' after 31*tbase,
    '1' after 40*tbase, '0' after 41*tbase;

  tb_exp_full <= 'U', '0' after 1*tbase,
    '1' after 10*tbase, '0' after 18*tbase,
    '1' after 21*tbase, '0' after 30*tbase,
    '1' after 30*tbase, '0' after 40*tbase;

  tb_exp_data_out <= "UUUUUUUU", "11111111" after 1*tbase,
    "01110011" after 10*tbase,
    "01100011" after 21*tbase,
    "11110000" after 30*tbase;

  tb_error <= '0' when
    (tb_exp_data_out = tb_data_out) 
    and (tb_exp_full = tb_full) else '1';

end TESTBENCH;