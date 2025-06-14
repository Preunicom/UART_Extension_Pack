library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_I2C_Wrapper is
  Port (
    tb_error : out std_logic
  );
end TB_I2C_Wrapper;

architecture TESTBENCH of TB_I2C_Wrapper is
  component I2C_Wrapper
    Generic (
      HOST_DATA_BITS : integer := 8;
      -- IN_FREQ_HZ has to be minimum 4*I2C_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      I2C_FREQ_HZ : integer := 100000
    );
    Port ( 
      clk, rst : in STD_LOGIC;
      write_en : in std_logic;
      access_mode : in std_logic_vector(1 downto 0); -- unused
      unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
      unit_data_out : out std_logic_vector(13 downto 0);
      scheduler_wanted : out std_logic;
      scheduler_done : in std_logic;
      error_to_host : out std_logic := '0';
      error_from_host : out std_logic := '0';
      SCL : inout std_logic;
      SDA : inout std_logic
    );
  end component;

  signal tb_clk : STD_LOGIC;
  signal tb_rst : STD_LOGIC;

  signal tb_write_en : std_logic;
  signal tb_access_mode : std_logic_vector(1 downto 0); --*0: set, *1: get
  signal tb_unit_data_in : STD_LOGIC_VECTOR(7 downto 0);
  signal tb_unit_data_out, tb_exp_unit_data_out : STD_LOGIC_VECTOR(13 downto 0);
  signal tb_scheduler_wanted, tb_exp_scheduler_wanted : std_logic;
  signal tb_scheduler_done : std_logic;
  signal tb_error_to_host, tb_exp_error_to_host : std_logic := '0';
  signal tb_error_from_host, tb_exp_error_from_host : std_logic := '0'; 
  signal tb_SCL, tb_exp_SCL, tb_SCL_no_pullup : std_logic;
  signal tb_SDA, tb_exp_SDA, tb_SDA_no_pullup : STD_LOGIC;

  constant tbase : time := 100 ns;
  constant tbase_scl : time := 10000 ns;

begin

  COMP: I2C_Wrapper generic map(8, 10000000, 100000) port map(tb_clk, tb_rst, tb_write_en, tb_access_mode, tb_unit_data_in, tb_unit_data_out, tb_scheduler_wanted, tb_scheduler_done, tb_error_to_host, tb_error_from_host, tb_SCL_no_pullup, tb_SDA_no_pullup);

  tb_SDA <= tb_SDA_no_pullup when tb_SDA_no_pullup /= 'Z' else 'H';
  tb_SCL <= tb_SCL_no_pullup when tb_SCL_no_pullup /= 'Z' else 'H';

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

  -- 100 KHz
  CLOCK_CLA: process
  begin
    tb_exp_SCL <= '0';
    wait for 1*tbase; -- Init Prescaler because of reset
    for i in 199 downto 0 loop
      tb_exp_SCL <= '0';
      wait for tbase_scl/2;
      tb_exp_SCL <= 'H';
      wait for tbase_scl/2;
    end loop;
    wait;
  end process;

  tb_rst <= '1', '0' after 2*tbase;

  tb_write_en <= '0',
    '1' after 10*tbase, '0' after 11*tbase,
    '1' after 20*tbase, '0' after 21*tbase,
    '1' after 2500*tbase, '0' after 2501*tbase,
    '1' after 2550*tbase, '0' after 2551*tbase,
    '1' after 2600*tbase, '0' after 2601*tbase; -- skipped with error

  tb_access_mode <= "00",
    "01" after 10*tbase, "00" after 11*tbase, -- Set adr.
    "00" after 20*tbase, "00" after 21*tbase, -- Send data
    "00" after 2500*tbase, "00" after 2501*tbase, -- Send data
    "10" after 2550*tbase, "00" after 2551*tbase, -- Recv data
    "00" after 2600*tbase, "00" after 2601*tbase; -- Send data

  tb_unit_data_in <= "00000000",
     "11000001" after 10*tbase, "00000000" after 11*tbase, -- 0x41
     "00001111" after 20*tbase, "00000000" after 21*tbase, -- 0x0F
     "10000001" after 2500*tbase, "00000000" after 2501*tbase, -- 0x81
     "00000000" after 2550*tbase, "00000000" after 2551*tbase, -- 0x00 (ignored - recv mode)
     "11110000" after 2600*tbase, "00000000" after 2601*tbase; -- 0xF0

  tb_scheduler_done <= '0',
    '1' after 6200*tbase, '0' after 6201*tbase;

  tb_SDA_no_pullup <= 'Z',
    '0' after 1002*tbase, 'Z' after 1102*tbase, --Adr ACK
    '0' after 1902*tbase, 'Z' after 2002*tbase, --Data ACK
    '0' after 3402*tbase, 'Z' after 3502*tbase, --Adr ACK
    '0' after 4302*tbase, 'Z' after 4402*tbase, --Data ACK
    '0' after 5302*tbase, 'Z' after 5402*tbase, --Adr ACK
    '0' after 5402*tbase, '0' after 5502*tbase, 'Z' after 5602*tbase, 'Z' after 5702*tbase, '0' after 5802*tbase, '0' after 5902*tbase, '0' after 6002*tbase, 'Z' after 6102*tbase; -- DATA (0x31)

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    "00000000ZZ000Z" after 6155*tbase, (others => '0') after 6200*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 6155*tbase, '0' after 6200*tbase;
  
  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0',
    '1' after 2601*tbase, '0' after 2602*tbase;

  tb_exp_SDA <= 'H',
    '0' after 153*tbase, --START
    'H' after 202*tbase, '0' after 302*tbase, '0' after 402*tbase, '0' after 502*tbase, '0' after 602*tbase, '0' after 702*tbase, 'H' after 802*tbase, '0' after 902*tbase, -- ADR (0x82)
    '0' after 1002*tbase, --ACK
    '0' after 1102*tbase, '0' after 1202*tbase, '0' after 1302*tbase, '0' after 1402*tbase, 'H' after 1502*tbase, 'H' after 1602*tbase, 'H' after 1702*tbase, 'H' after 1802*tbase, -- DATA (0x0F)
    '0' after 1902*tbase, --ACK
    '0' after 2002*tbase, --STOP_PREP
    'H' after 2053*tbase, --STOP
    '0' after 2553*tbase, --START
    'H' after 2602*tbase, '0' after 2702*tbase, '0' after 2802*tbase, '0' after 2902*tbase, '0' after 3002*tbase, '0' after 3102*tbase, 'H' after 3202*tbase, '0' after 3302*tbase, -- ADR (0x82)
    '0' after 3402*tbase, --ACK
    'H' after 3502*tbase, '0' after 3602*tbase, '0' after 3702*tbase, '0' after 3802*tbase, '0' after 3902*tbase, '0' after 4002*tbase, '0' after 4102*tbase, 'H' after 4202*tbase, -- DATA (0x81)
    '0' after 4302*tbase, --ACK
    'H' after 4402*tbase, --RS_PREP
    '0' after 4453*tbase, -- RS (Repeated Start)
    'H' after 4502*tbase, '0' after 4602*tbase, '0' after 4702*tbase, '0' after 4802*tbase, '0' after 4902*tbase, '0' after 5002*tbase, 'H' after 5102*tbase, 'H' after 5202*tbase, -- ADR (0x83)
    '0' after 5302*tbase, --ACK
    '0' after 5402*tbase, '0' after 5502*tbase, 'H' after 5602*tbase, 'H' after 5702*tbase, '0' after 5802*tbase, '0' after 5902*tbase, '0' after 6002*tbase, 'H' after 6102*tbase, -- DATA (0x31)
    '0' after 6202*tbase, --ACK
    '0' after 6302*tbase, --STOP_PREP
    'H' after 6353*tbase; --STOP
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_SCL = tb_SCL) 
    and (tb_exp_SDA = tb_SDA) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end TESTBENCH;