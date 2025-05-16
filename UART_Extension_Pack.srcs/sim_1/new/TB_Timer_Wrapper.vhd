library IEEE;
  use IEEE.STD_LOGIC_1164.all;

entity TB_Timer_Wrapper is
  Port(
    signal tb_error : out std_logic
  );
end entity;

architecture Behavioral of TB_Timer_Wrapper is
  component Timer_Wrapper
    generic (
      HOST_DATA_BITS : integer := 8;
      FPGA_FREQ      : integer := 12000000;
      HOST_BAUD      : integer := 1000000
    );
    port (
      clk, rst         : in  STD_LOGIC;
      write_en         : in  std_logic;
      access_mode      : in  std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
      unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
      unit_data_out    : out STD_LOGIC_VECTOR(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done   : in  std_logic;
      error_to_host    : out std_logic := '0';
      error_from_host  : out std_logic := '0'
    );
  end component;
  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en                                  : std_logic;
  signal tb_access_mode                               : std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
  signal tb_unit_data_in                              : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out       : STD_LOGIC_VECTOR(13 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done                            : std_logic;
  signal tb_error_to_host, tb_exp_error_to_host       : std_logic := '0';
  signal tb_error_from_host, tb_exp_error_from_host   : std_logic := '0'; 

  constant tbase : time := 100 ns;
begin
  COMP: Timer_Wrapper generic map(8, 10000000, 1000000) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host);

  -- 10 MHz
  CLOCK: process
  begin
    for i in 5000 downto 0 loop
      tb_clk <= '1';
      wait for tbase / 2;
      tb_clk <= '0';
      wait for tbase / 2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_write_en <= '0',
    '1' after 2*tbase, '0' after 3*tbase, -- set start_value (0xFF)
    '1' after 212*tbase, '0' after 213*tbase, -- restart
    '1' after 222*tbase, '0' after 223*tbase, -- en
    '1' after 505*tbase, '0' after 506*tbase, -- set start_value (0xFE)
    '1' after 1400*tbase, '0' after 1401*tbase, -- set prescale factor
    '1' after 2400*tbase, '0' after 2401*tbase, -- set start_value (0xFF)
    '1' after 4000*tbase, '0' after 4001*tbase; -- en

  tb_access_mode <= "00",
    "11" after 2*tbase,
    "01" after 212*tbase,
    "00" after 222*tbase,
    "11" after 505*tbase,
    "10" after 1400*tbase,
    "11" after 2400*tbase,
    "00" after 4000*tbase;

  tb_unit_data_in <= "00000000",
    "11111111" after 2*tbase,
    "00000000" after 212*tbase,
    "11111111" after 222*tbase,
    "11111110" after 55*tbase,
    "00000010" after 1400*tbase,
    "11111111" after 2400*tbase,
    "00000000" after 4000*tbase;

  tb_scheduler_done <= '0',
    '1' after 321*tbase, '0' after 322*tbase,
    '1' after 531*tbase, '0' after 532*tbase,
    '1' after 921*tbase, '0' after 922*tbase,
    '1' after 1391*tbase, '0' after 1392*tbase,
    '1' after 1791*tbase, '0' after 1792*tbase,
    '1' after 2191*tbase, '0' after 2192*tbase,
    '1' after 2591*tbase, '0' after 2592*tbase,
    '1' after 2991*tbase, '0' after 2992*tbase,
    '1' after 3391*tbase, '0' after 3392*tbase,
    '1' after 3791*tbase, '0' after 3792*tbase;

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    (others => '1') after 302*tbase, (others => '0') after 321*tbase,
    (others => '1') after 502*tbase, (others => '0') after 531*tbase,
    (others => '1') after 902*tbase, (others => '0') after 921*tbase,
    (others => '1') after 1302*tbase, (others => '0') after 1391*tbase,
    (others => '1') after 2102*tbase, (others => '0') after 2191*tbase,
    (others => '1') after 2502*tbase, (others => '0') after 2591*tbase,
    (others => '1') after 2902*tbase, (others => '0') after 2991*tbase,
    (others => '1') after 3302*tbase, (others => '0') after 3391*tbase,
    (others => '1') after 3702*tbase, (others => '0') after 3791*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 302*tbase, '0' after 321*tbase,
    '1' after 502*tbase, '0' after 531*tbase,
    '1' after 902*tbase, '0' after 921*tbase,
    '1' after 1302*tbase, '0' after 1391*tbase,
    '1' after 2102*tbase, '0' after 2191*tbase,
    '1' after 2502*tbase, '0' after 2591*tbase,
    '1' after 2902*tbase, '0' after 2991*tbase,
    '1' after 3302*tbase, '0' after 3391*tbase,
    '1' after 3702*tbase, '0' after 3791*tbase;
  
  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0';
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end architecture;