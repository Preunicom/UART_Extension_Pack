library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_I2C_Communication is
  Port (
    tb_error : out std_logic
  );
end TB_I2C_Communication;

architecture TESTBENCH of TB_I2C_Communication is
  component I2C_Communication
    port (
      clk, rst, clk_en_read, clk_en_write : in std_logic;
      SDA_in : in std_logic;
      SDA_out : out std_logic;
      write_en : in std_logic;
      addr_data : in std_logic_vector(6 downto 0);
      mode_recv : in std_logic; -- 0: write, 1: read
      send_data : in std_logic_vector(7 downto 0);
      data_saved : out std_logic;
      recv_data : out std_logic_vector(7 downto 0);
      recv_data_valid : out std_logic;
      is_idle : out std_logic;
      error : out std_logic
    );
  end component;

  signal tb_clk, tb_rst : std_logic;
  signal tb_clk_en_read : std_logic := '0';
  signal tb_clk_en_write : std_logic := '1';
  signal tb_SDA, tb_exp_SDA : std_logic;
  signal tb_write_en : std_logic;
  signal tb_addr_data : std_logic_vector(6 downto 0);
  signal tb_mode_recv : std_logic; -- 0: write, 1: read
  signal tb_send_data : std_logic_vector(7 downto 0);
  signal tb_data_saved, tb_exp_data_saved : std_logic;
  signal tb_recv_data, tb_exp_recv_data : std_logic_vector(7 downto 0);
  signal tb_recv_data_valid, tb_exp_recv_data_valid : std_logic;
  signal tb_is_idle, tb_exp_is_idle : std_logic;
  signal tb_error_unit, tb_exp_error_unit : std_logic;
  constant tbase : time := 100 ns;
  signal tb_SDA_no_pullup : std_logic := 'Z';

begin
  COMP: I2C_Communication port map(tb_clk, tb_rst, tb_clk_en_read, tb_clk_en_write, tb_SDA, tb_SDA_no_pullup, tb_write_en, tb_addr_data, tb_mode_recv, tb_send_data, tb_data_saved, tb_recv_data, tb_recv_data_valid, tb_is_idle, tb_error_unit);

  tb_SDA <= '0' when tb_SDA_no_pullup = '0' else 'H';

  -- 10 MHz
  CLOCK: process
  begin
    for i in 100 downto 0 loop
      tb_clk_en_write <= not tb_clk_en_write;
      tb_clk_en_read <= not tb_clk_en_read;
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_SDA_no_pullup <= 'Z';

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 11*tbase;

  tb_addr_data <= (others => '0'),
    "0000011" after 10*tbase, (others => '0') after 11*tbase;

  tb_mode_recv <= '0',
    '0' after 10*tbase, '0' after 11*tbase;

  tb_send_data <= (others => '0'),
     "01100110" after 10*tbase, (others => '0') after 11*tbase;

  tb_exp_data_saved <= 'U', '0' after 1*tbase,
    '1' after 10*tbase, '0' after 11*tbase;

  tb_exp_recv_data <= (others => 'U'), (others => '1') after 1*tbase;

  tb_exp_recv_data_valid <= 'U', '0' after 1*tbase;

  tb_exp_error_unit <= 'U', '0' after 1*tbase;

  tb_exp_is_idle <= 'U', '1' after 1*tbase,
    '0' after 13*tbase, '1' after 51*tbase;

  tb_exp_SDA <= 'H',
    '0' after 12*tbase, 'H' after 23*tbase,
    '0' after 27*tbase, 'H' after 29*tbase,
    '0' after 31*tbase, 'H' after 33*tbase,
    '0' after 37*tbase, 'H' after 41*tbase,
    '0' after 45*tbase, 'H' after 47*tbase,
    '0' after 49*tbase, 'H' after 50*tbase;

  tb_error <= '0' when 
    (tb_exp_data_saved = tb_data_saved)
    and (tb_exp_error_unit = tb_error_unit)
    and (tb_exp_SDA = tb_SDA)
    and (tb_exp_recv_data = tb_recv_data)
    and (tb_exp_is_idle = tb_is_idle)
    and (tb_exp_recv_data_valid = tb_recv_data_valid) else '1';

end TESTBENCH;
