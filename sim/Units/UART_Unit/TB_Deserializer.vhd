library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Deserializer is
  Port (
    tb_error : out std_logic
  );
end TB_Deserializer;

architecture TESTBENCH of TB_Deserializer is
  component Deserializer
    Generic(
      -- DATA_BITS + STOP_BITS + PARITY_ACTIVE <= 15 has to be fullfilled
      DATA_BITS : integer := 8;
      STOP_BITS : integer := 1;
      PARITY_ACTIVE : integer := 0; -- 0: No Parity; 1: Even or Odd Parity
      PARITY_MODE : integer := 0 -- 0: Even Parity; 1: Odd Parity
    );
    Port ( 
      clk, clk_en_prescaled, rst : in std_logic;
      serial_in : in std_logic;
      parallel_out : out std_logic_vector(DATA_BITS-1 downto 0);
      frame_error, parity_error : out std_logic;
      data_valid : out std_logic
  );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_clk_en_prescaled : std_logic;
  signal tb_rst : STD_LOGIC;
  signal tb_serial_in : std_logic;
  signal tb_parallel_out, tb_exp_parallel_out : std_logic_vector(7 downto 0);
  signal tb_frame_error, tb_exp_frame_error : std_logic;
  signal tb_parity_error, tb_exp_parity_error : std_logic;
  signal tb_data_valid, tb_exp_data_valid : std_logic;
  constant tbase : time := 100 ns;
begin
    COMP: Deserializer generic map(8, 1, 1, 0) port map(tb_clk, tb_clk_en_prescaled, tb_rst, tb_serial_in, tb_parallel_out, tb_frame_error, tb_parity_error, tb_data_valid);

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

  -- reset Deserializer to demonstrate real usage while idle
  tb_rst <= '1', '0' after 20*tbase,
    '1' after 32*tbase, '0' after 40*tbase,
    '1' after 52*tbase, '0' after 60*tbase,
    '1' after 72*tbase, '0' after 80*tbase,
    '1' after 92*tbase, '0' after 100*tbase;

  tb_serial_in <= '1',
    '0' after 21*tbase, '0' after 22*tbase, '0' after 23*tbase, '0' after 24*tbase, '0' after 25*tbase, '1' after 26*tbase, '1' after 27*tbase, '1' after 28*tbase, '1' after 29*tbase, '0' after 30*tbase, '1' after 31*tbase, -- (0xF0)
    '0' after 41*tbase, '1' after 42*tbase, '0' after 43*tbase, '0' after 44*tbase, '0' after 45*tbase, '0' after 46*tbase, '0' after 47*tbase, '0' after 48*tbase, '0' after 49*tbase, '0' after 50*tbase, '1' after 51*tbase, -- (0x01) (PARITY ERROR)
    '0' after 61*tbase, '1' after 62*tbase, '1' after 63*tbase, '1' after 64*tbase, '1' after 65*tbase, '1' after 66*tbase, '1' after 67*tbase, '1' after 68*tbase, '1' after 69*tbase, '0' after 70*tbase, '1' after 71*tbase, -- (0xFF)
    '0' after 81*tbase, '1' after 82*tbase, '1' after 83*tbase, '1' after 84*tbase, '1' after 85*tbase, '0' after 86*tbase, '0' after 87*tbase, '0' after 88*tbase, '0' after 89*tbase, '0' after 90*tbase, '1' after 93*tbase, -- (0x0F) (FRAME ERROR)
    '0' after 101*tbase, '1' after 102*tbase, '1' after 103*tbase, '0' after 104*tbase, '0' after 105*tbase, '0' after 106*tbase, '0' after 107*tbase, '0' after 108*tbase, '1' after 109*tbase, '1' after 110*tbase, '1' after 111*tbase; -- (0x83)

  tb_exp_data_valid <= 'U', '0' after 1*tbase,
    '1' after 31*tbase, '0' after 32*tbase,
    '1' after 51*tbase, '0' after 52*tbase,
    '1' after 71*tbase, '0' after 72*tbase,
    '1' after 91*tbase, '0' after 92*tbase,
    '1' after 111*tbase, '0' after 112*tbase;

  tb_exp_parallel_out <= (others => 'U'), "00000000" after 1*tbase,
    x"F0" after 31*tbase, "00000000" after 32*tbase,
    x"01" after 51*tbase, "00000000" after 52*tbase,
    x"FF" after 71*tbase, "00000000" after 72*tbase,
    x"0F" after 91*tbase, "00000000" after 92*tbase,
    x"83" after 111*tbase, "00000000" after 112*tbase;

  tb_exp_frame_error <= 'U', '0' after 1*tbase,
    '1' after 91*tbase, '0' after 92*tbase;

  tb_exp_parity_error <= 'U', '0' after 1*tbase,
    '1' after 51*tbase, '0' after 52*tbase;

  tb_error <= '0' when
    (tb_exp_data_valid = tb_data_valid) 
    and (tb_exp_frame_error = tb_frame_error)
    and (tb_exp_parallel_out = tb_parallel_out)
    and (tb_exp_parity_error = tb_parity_error) else '1';

end TESTBENCH;
