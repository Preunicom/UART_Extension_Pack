--! @file
--! @brief Testbench for the MUX
--! @details
--! This file contains the testbench for the MUX entity.  
--! It tests:
--! - Normal operation

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.UnitDataArray_Type_PKG.ALL;

entity TB_MUX is
  Port(
    signal tb_error : out std_logic --! '0' if everything works like expected, '1' otherwise.
  );
end TB_MUX;

architecture TESTBENCH of TB_MUX is
  component MUX
    generic (
      WIDTH : integer := 8 --! Amount of used bits of one std_logic_vector in the unit_data_array.
    );
    port (
      clk           : in std_logic; --! The clock signal.
      rst           : in std_logic; --! The reset signal.
      control       : in  STD_LOGIC_VECTOR(5 downto 0); --! Control signal to choose the unit to extract the data from.
      control_valid : in std_logic; --! Enable signal for the control signal.
      inp           : in unit_data_array; --! The input unit data as array (0...63) of vector of std_logic_vector(0...13)
      outp          : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0); --! The chosen extracted unit data.
      mux_unit_number_out : out std_logic_vector(5 downto 0); --! The number of the unit the data was extracted from.
      outp_valid    : out std_logic --! Enable for outp and mux_unit_number_out signals.
    );
  end component;

  subtype unit_data_array_t is unit_data_array(63 downto 0);

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_control : STD_LOGIC_VECTOR(5 downto 0);
  signal tb_control_valid : std_logic;
  signal tb_inp : unit_data_array_t;
  signal tb_outp, tb_exp_outp : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_mux_unit_number_out, tb_exp_mux_unit_number_out : std_logic_vector(5 downto 0); 
  signal tb_outp_valid, tb_exp_outp_valid : std_logic;

  constant tbase : time := 100 ns;
begin
  COMP: MUX generic map(8) port map(tb_clk, tb_rst, tb_control, tb_control_valid, tb_inp, tb_outp, tb_mux_unit_number_out, tb_outp_valid);

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

  tb_control <= "000000",
    "111111" after 19.5*tbase, "000000" after 20.5*tbase,
    "111111" after 29.5*tbase, "000000" after 30.5*tbase; 

  tb_control_valid <= '0',
    '1' after 19.5*tbase, '0' after 20.5*tbase;

  tb_inp(62 downto 0) <= (others => (others => '0'));
  tb_inp(63) <= (others => '0'),
    "00000001010011" after 19.5*tbase, (others => '0') after 20.5*tbase,
    "00000001010000" after 29.5*tbase, (others => '0') after 30.5*tbase;

  tb_exp_outp <= (others => 'U'), x"00" after 1*tbase,
    x"53" after 20*tbase, x"00" after 21*tbase,
    x"50" after 30*tbase, x"00" after 31*tbase;

  tb_exp_mux_unit_number_out <= "UUUUUU", "000000" after 1*tbase,
    "111111" after 20*tbase, "000000" after 21*tbase,
    "111111" after 30*tbase, "000000" after 31*tbase;

  tb_exp_outp_valid <= 'U', '0' after 1*tbase,
    '1' after 20*tbase, '0' after 21*tbase;

  tb_error <= '0' when
    (tb_exp_outp_valid = tb_outp_valid) 
    and (tb_exp_mux_unit_number_out = tb_mux_unit_number_out) 
    and (tb_exp_outp = tb_outp) else '1';

end TESTBENCH;