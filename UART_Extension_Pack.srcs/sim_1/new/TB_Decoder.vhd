library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Decoder is
end TB_Decoder;

architecture TESTBENCH of TB_Decoder is
  component Decoder
    Generic (
      DATA_BITS : integer := 8;
      IN_FREQ_HZ : integer := 12000000
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      uart_inp : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_inp_valid : in std_logic;
      out_en : out std_logic;
      access_mode : out std_logic_vector(1 downto 0);
      unit_number : out std_logic_vector(2 downto 0); 
      unit_data : out std_logic_vector(DATA_BITS-1 downto 0)
    );
  end component;
  signal tb_clk, tb_rst : std_logic;
  signal tb_uart_inp : std_logic_vector(7 downto 0);
  signal tb_uart_inp_valid : std_logic;
  signal tb_out_en : std_logic;
  signal tb_access_mode : std_logic_vector(1 downto 0);
  signal tb_unit_number : std_logic_vector(2 downto 0); 
  signal tb_unit_data : std_logic_vector(7 downto 0);
  constant tbase : time := 10 ns;
begin
  DEC: Decoder generic map(8, 60000) port map(tb_clk, tb_rst, tb_uart_inp, tb_uart_inp_valid, tb_out_en, tb_access_mode, tb_unit_number, tb_unit_data);

  CLK: process
  begin
    for i in 1000 downto 0 loop
      tb_clk <= '1';
      wait for tbase/2;
      tb_clk <= '0';
      wait for tbase/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 1*tbase;
  tb_uart_inp <= "00011001", "11111111" after 50*tbase, 
                  "00000110" after 100*tbase, "00001111" after 150*tbase;
  tb_uart_inp_valid <= '0', '1' after 5*tbase, '0' after 6*tbase, '1' after 50*tbase, '0' after 51*tbase,
                  '1' after 100*tbase, '0' after 101*tbase, '1' after 150*tbase, '0' after 151*tbase;
end TESTBENCH;
