library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity TB_Decoder is
  Port(
    signal tb_error : out std_logic
  );
end TB_Decoder;

architecture Behavioral of TB_Decoder is
  component Decoder
    Generic (
      DATA_BITS : integer := 8;
      FPGA_FREQ : integer := 12000000;
      HOST_BAUD : integer := 1000000
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      uart_inp : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_inp_valid : in std_logic;
      uart_error : in std_logic;
      out_en : out std_logic;
      access_mode : out std_logic_vector(1 downto 0);
      unit_number : out std_logic_vector(5 downto 0); 
      unit_data : out std_logic_vector(DATA_BITS-1 downto 0)
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;
  signal tb_uart_inp : std_logic_vector(7 downto 0);
  signal tb_uart_inp_valid : std_logic;
  signal tb_uart_error : std_logic;
  signal tb_out_en, tb_exp_out_en : std_logic;
  signal tb_access_mode, tb_exp_access_mode : std_logic_vector(1 downto 0);
  signal tb_unit_number, tb_exp_unit_number : std_logic_vector(5 downto 0); 
  signal tb_unit_data, tb_exp_unit_data : std_logic_vector(7 downto 0);
  constant tbase : time := 100 ns;
begin
  COMP: Decoder generic map(8, 10000000, 1000000) port map(tb_clk, tb_rst, tb_uart_inp, tb_uart_inp_valid, tb_uart_error, tb_out_en, tb_access_mode, tb_unit_number, tb_unit_data);

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

  tb_uart_inp_valid <= '0', 
    '1' after 2*tbase, '0' after 3*tbase,
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 28*tbase, '0' after 29*tbase,
    '1' after 36*tbase, '0' after 37*tbase,
    '1' after 44*tbase, '0' after 45*tbase,
    '1' after 52*tbase, '0' after 53*tbase,
    '1' after 70*tbase, '0' after 71*tbase,
    '1' after 450*tbase, '0' after 451*tbase,
    '1' after 458*tbase, '0' after 459*tbase;

  tb_uart_inp <= 
    "01000001" after 2*tbase,
    "00000010" after 10*tbase,
    "10000011" after 18*tbase,
    "00000100" after 36*tbase,
    "00000101" after 44*tbase,
    "00000110" after 52*tbase,
    "00000111" after 70*tbase,
    "11001001" after 450*tbase,
    "00001010" after 458*tbase;

  tb_uart_error <= '0', '1' after 44*tbase, '0' after 52*tbase;

  tb_exp_out_en <= 'U', '0' after 1*tbase, 
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 36*tbase, '0' after 37*tbase,
    '0' after 52*tbase, '0' after 53*tbase,
    '1' after 458*tbase, '0' after 459*tbase;

  tb_exp_unit_number <= "UUUUUU", "000000" after 1*tbase,
    "000001" after 10*tbase,
    "000011" after 36*tbase,
    "000101" after 52*tbase,
    "001001" after 458*tbase;

  tb_exp_access_mode <= "UU", "00" after 1*tbase,
    "01" after 10*tbase,
    "10" after 36*tbase,
    "00" after 52*tbase,
    "11" after 458*tbase;

  tb_exp_unit_data <= "UUUUUUUU", "00000000" after 1*tbase,
    "00000010" after 10*tbase,
    "00000100" after 36*tbase,
    "00000110" after 52*tbase,
    "00001010" after 458*tbase;

  tb_error <= '0' when
    (tb_exp_out_en = tb_out_en) 
    and (tb_exp_unit_number = tb_unit_number)
    and (tb_exp_access_mode = tb_access_mode)
    and (tb_exp_unit_data = tb_unit_data) else '1';

end Behavioral;
