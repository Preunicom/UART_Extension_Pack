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
    '1' after 104*tbase, '0' after 105*tbase, -- set start_value (0xFF)
    '1' after 314*tbase, '0' after 315*tbase, -- restart
    '1' after 324*tbase, '0' after 325*tbase, -- en
    '1' after 607*tbase, '0' after 608*tbase, -- set start_value (0xFE)
    '1' after 1502*tbase, '0' after 1503*tbase, -- set prescale factor
    '1' after 2502*tbase, '0' after 2503*tbase, -- set start_value (0xFF)
    '1' after 4102*tbase, '0' after 4103*tbase; -- en

  tb_access_mode <= "00",
    "11" after 104*tbase,
    "01" after 314*tbase,
    "00" after 324*tbase,
    "11" after 607*tbase,
    "10" after 1502*tbase,
    "11" after 2502*tbase,
    "00" after 4102*tbase;

  tb_unit_data_in <= "00000000",
    "11111111" after 104*tbase,
    "00000000" after 314*tbase,
    "11111111" after 324*tbase,
    "11111110" after 157*tbase,
    "00000010" after 1502*tbase,
    "11111111" after 2502*tbase,
    "00000000" after 4102*tbase;

  tb_scheduler_done <= '0',
    '1' after 423*tbase, '0' after 424*tbase,
    '1' after 633*tbase, '0' after 634*tbase,
    '1' after 1023*tbase, '0' after 1024*tbase,
    '1' after 1493*tbase, '0' after 1494*tbase,
    '1' after 1893*tbase, '0' after 1894*tbase,
    '1' after 2293*tbase, '0' after 2294*tbase,
    '1' after 2693*tbase, '0' after 2694*tbase,
    '1' after 3093*tbase, '0' after 3094*tbase,
    '1' after 3493*tbase, '0' after 3494*tbase,
    '1' after 3893*tbase, '0' after 3894*tbase;

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    (others => '1') after 404*tbase, (others => '0') after 423*tbase,
    (others => '1') after 604*tbase, (others => '0') after 633*tbase,
    (others => '1') after 1004*tbase, (others => '0') after 1023*tbase,
    (others => '1') after 1404*tbase, (others => '0') after 1493*tbase,
    (others => '1') after 2204*tbase, (others => '0') after 2293*tbase,
    (others => '1') after 2604*tbase, (others => '0') after 2693*tbase,
    (others => '1') after 3004*tbase, (others => '0') after 3093*tbase,
    (others => '1') after 3404*tbase, (others => '0') after 3493*tbase,
    (others => '1') after 3804*tbase, (others => '0') after 3893*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 404*tbase, '0' after 423*tbase,
    '1' after 604*tbase, '0' after 633*tbase,
    '1' after 1004*tbase, '0' after 1023*tbase,
    '1' after 1404*tbase, '0' after 1493*tbase,
    '1' after 2204*tbase, '0' after 2293*tbase,
    '1' after 2604*tbase, '0' after 2693*tbase,
    '1' after 3004*tbase, '0' after 3093*tbase,
    '1' after 3404*tbase, '0' after 3493*tbase,
    '1' after 3804*tbase, '0' after 3893*tbase;
  
  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0';
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end architecture;