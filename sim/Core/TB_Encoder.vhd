library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity TB_Encoder is
  Port(
    signal tb_error : out std_logic
  );
end TB_Encoder;

architecture TESTBENCH of TB_Encoder is
  component Encoder
    Generic (
      DATA_BITS : integer := 8
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      write_en : in std_logic;
      uart_is_empty : in std_logic;
      unit_number : in std_logic_vector(5 downto 0);
      unit_data : in std_logic_vector(DATA_BITS-1 downto 0);
      uart_out : out std_logic_vector(DATA_BITS-1 downto 0);
      uart_out_valid : out std_logic;
      schedule_next : out std_logic
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en : std_logic;
  signal tb_uart_is_empty : std_logic;
  signal tb_unit_number : std_logic_vector(5 downto 0);
  signal tb_unit_data : std_logic_vector(7 downto 0);
  signal tb_uart_out, tb_exp_uart_out : std_logic_vector(7 downto 0);
  signal tb_uart_out_valid, tb_exp_uart_out_valid : std_logic;
  signal tb_schedule_next, tb_exp_schedule_next : std_logic;
  
  constant tbase : time := 100 ns;
begin
  COMP: Encoder generic map(8) port map(tb_clk, tb_rst, tb_write_en, tb_uart_is_empty, tb_unit_number, tb_unit_data, tb_uart_out, tb_uart_out_valid, tb_schedule_next);
  
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

  tb_write_en <= '0',
    '1' after 2*tbase, '0' after 3*tbase,
    '1' after 30*tbase, '0' after 31*tbase;

  -- needs 3 clock cycles after write_en to get to 0 (set state to S1, set uart_out_valid, [UART Unit] set full to 1)
  tb_uart_is_empty <= '1',
    '0' after 5*tbase, '1' after 12*tbase, -- send unit number
    '0' after 14*tbase, '1' after 22*tbase, -- send unit data
    '0' after 33*tbase, '1' after 40*tbase, -- send unit number
    '0' after 43*tbase, '1' after 52*tbase; -- send unit data

  tb_unit_number <= 
    "000001",
    "000010" after 30*tbase;

  tb_unit_data <= 
    "11110001",
    "00000011" after 30*tbase;

  tb_exp_schedule_next <= 'U', '1' after 1*tbase,
    '0' after 2*tbase, '1' after 12*tbase,
    '0' after 30*tbase, '1' after 40*tbase;

  tb_exp_uart_out_valid <= 'U' , '0' after 1*tbase,
    '1' after 3*tbase, '0' after 4*tbase,
    '1' after 12*tbase, '0' after 13*tbase,
    '1' after 31*tbase, '0' after 32*tbase,
    '1' after 40*tbase, '0' after 41*tbase;

  tb_exp_uart_out <= "UUUUUUUU", "00000000" after 1*tbase,
    "00000001" after 3*tbase, -- unit number
    "11110001" after 12*tbase, -- unit data
    "00000010" after 31*tbase, -- unit number
    "00000011" after 40*tbase; -- unit data
  
  tb_error <= '0' when 
    (tb_exp_schedule_next = tb_schedule_next)
    and (tb_exp_uart_out = tb_uart_out)
    and (tb_exp_uart_out_valid = tb_uart_out_valid) else '1';

end TESTBENCH;