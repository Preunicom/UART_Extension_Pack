library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Buffer_Register_Deserializer is
  Port (
    tb_error : out std_logic
  );
end TB_Buffer_Register_Deserializer;

architecture TESTBENCH of TB_Buffer_Register_Deserializer is
component Buffer_Register_Deserializer
    Generic(
      DATA_BITS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      parallel_in : in std_logic_vector(DATA_BITS-1 downto 0);
      frame_error_in, parity_error_in : in std_logic;
      write_en : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error_out, parity_error_out : out std_logic;
      new_data : out std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_parallel_in : std_logic_vector(7 downto 0);
  signal tb_frame_error_in : std_logic;
  signal tb_parity_error_in : std_logic;
  signal tb_write_en : std_logic;
  signal tb_parallel_out, tb_exp_parallel_out : std_logic_vector(7 downto 0);
  signal tb_frame_error_out, tb_exp_frame_error_out : std_logic;
  signal tb_parity_error_out, tb_exp_parity_error_out : std_logic;
  signal tb_new_data, tb_exp_new_data : std_logic;
  constant tbase : time := 100 ns;
begin
    COMP: Buffer_Register_Deserializer generic map(8) port map(tb_clk, tb_rst, tb_parallel_in, tb_frame_error_in, tb_parity_error_in, tb_write_en, tb_parallel_out, tb_frame_error_out, tb_parity_error_out, tb_new_data);

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

  tb_parallel_in <= "00000000",
    "10100010" after 10*tbase, "00000000" after 15*tbase,
    "00001111" after 30*tbase, "00000000" after 35*tbase,
    "00001111" after 50*tbase, "00000000" after 55*tbase,
    "00001111" after 70*tbase, "00000000" after 75*tbase,
    "11110000" after 90*tbase, "00000000" after 95*tbase;

  tb_frame_error_in <= '0',
    '0' after 10*tbase, '0' after 15*tbase,
    '1' after 30*tbase, '0' after 35*tbase,
    '0' after 50*tbase, '0' after 55*tbase,
    '0' after 70*tbase, '0' after 75*tbase,
    '0' after 90*tbase, '0' after 95*tbase;

  tb_parity_error_in <= '0',
    '0' after 10*tbase, '0' after 15*tbase,
    '0' after 30*tbase, '0' after 35*tbase,
    '0' after 50*tbase, '0' after 55*tbase,
    '1' after 70*tbase, '0' after 75*tbase,
    '0' after 90*tbase, '0' after 95*tbase;

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 15*tbase,
    '1' after 30*tbase, '0' after 35*tbase,
    '1' after 50*tbase, '0' after 55*tbase,
    '1' after 70*tbase, '0' after 75*tbase,
    '1' after 90*tbase, '0' after 95*tbase;

  tb_exp_frame_error_out <= 'U', '0' after 1*tbase,
    '0' after 10*tbase,
    '1' after 30*tbase,
    '0' after 50*tbase,
    '0' after 70*tbase,
    '0' after 90*tbase;

   tb_exp_parity_error_out <= 'U', '0' after 1*tbase,
    '0' after 10*tbase,
    '0' after 30*tbase,
    '0' after 50*tbase,
    '1' after 70*tbase,
    '0' after 90*tbase;

  tb_exp_new_data <= 'U', '0' after 1*tbase,
    '1' after 10*tbase, '0' after 15*tbase,
    '1' after 30*tbase, '0' after 35*tbase,
    '1' after 50*tbase, '0' after 55*tbase,
    '1' after 70*tbase, '0' after 75*tbase,
    '1' after 90*tbase, '0' after 95*tbase;

  tb_exp_parallel_out <= "UUUUUUUU", "00000000" after 1*tbase,
    "10100010" after 10*tbase,
    "00001111" after 30*tbase,
    "00001111" after 50*tbase,
    "00001111" after 70*tbase,
    "11110000" after 90*tbase;

  tb_error <= '0' when
    (tb_exp_frame_error_out = tb_frame_error_out) 
    and (tb_exp_new_data = tb_new_data)
    and (tb_exp_parallel_out = tb_parallel_out)
    and (tb_exp_parity_error_out = tb_parity_error_out) else '1';

end TESTBENCH;