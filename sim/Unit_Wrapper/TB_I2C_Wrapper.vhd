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
      access_mode : in std_logic_vector(1 downto 0);
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

  signal SCL_temp : std_logic;
  signal SCL_en : std_logic;

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
    SCL_temp <= '0';
    wait for 1*tbase; -- Init Prescaler because of reset
    for i in 199 downto 0 loop
      SCL_temp <= '0';
      wait for tbase_scl/2;
      SCL_temp <= 'H';
      wait for tbase_scl/2;
    end loop;
    wait;
  end process;

  SCL_en <= '1', '0' after 1*tbase,
    '1' after 101*tbase, '0' after 1951*tbase,
    '1' after 2601*tbase, '0' after 6351*tbase;

  tb_exp_SCL <= '0' when SCL_en = '1' and SCL_temp = '0' else 'H';

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
    '0' after 927*tbase, 'Z' after 1027*tbase, --Adr ACK
    '0' after 1827*tbase, 'Z' after 1927*tbase, --Data ACK
    '0' after 3427*tbase, 'Z' after 3527*tbase, --Adr ACK
    '0' after 4327*tbase, 'Z' after 4427*tbase, --Data ACK
    '0' after 5327*tbase, 'Z' after 5427*tbase, --Adr ACK
    '0' after 5427*tbase, '0' after 5527*tbase, 'Z' after 5627*tbase, 'Z' after 5727*tbase, '0' after 5827*tbase, '0' after 5927*tbase, '0' after 6027*tbase, 'Z' after 6127*tbase; -- DATA (0x31)

  tb_exp_unit_data_out <= (others => 'U'), (others => '0') after 1*tbase,
    "00000000ZZ000Z" after 6179*tbase, (others => '0') after 6200*tbase;

  tb_exp_scheduler_wanted <= 'U', '0' after 1*tbase,
    '1' after 6179*tbase, '0' after 6200*tbase;
  
  tb_exp_error_to_host <= '0';

  tb_exp_error_from_host <= '0',
    '1' after 2601*tbase, '0' after 2602*tbase;

  tb_exp_SDA <= 'H',
    '0' after 77*tbase, --START
    'H' after 127*tbase, '0' after 227*tbase, '0' after 327*tbase, '0' after 427*tbase, '0' after 527*tbase, '0' after 627*tbase, 'H' after 727*tbase, '0' after 827*tbase, -- ADR (0x82)
    '0' after 927*tbase, --ACK
    '0' after 1027*tbase, '0' after 1127*tbase, '0' after 1227*tbase, '0' after 1327*tbase, 'H' after 1427*tbase, 'H' after 1527*tbase, 'H' after 1627*tbase, 'H' after 1727*tbase, -- DATA (0x0F)
    '0' after 1827*tbase, --ACK
    '0' after 1927*tbase, --STOP_PREP
    'H' after 1977*tbase, --STOP
    '0' after 2577*tbase, --START
    'H' after 2627*tbase, '0' after 2727*tbase, '0' after 2827*tbase, '0' after 2927*tbase, '0' after 3027*tbase, '0' after 3127*tbase, 'H' after 3227*tbase, '0' after 3327*tbase, -- ADR (0x82)
    '0' after 3427*tbase, --ACK
    'H' after 3527*tbase, '0' after 3627*tbase, '0' after 3727*tbase, '0' after 3827*tbase, '0' after 3927*tbase, '0' after 4027*tbase, '0' after 4127*tbase, 'H' after 4227*tbase, -- DATA (0x81)
    '0' after 4327*tbase, --ACK
    'H' after 4427*tbase, --RS_PREP
    '0' after 4477*tbase, -- RS (Repeated Start)
    'H' after 4527*tbase, '0' after 4627*tbase, '0' after 4727*tbase, '0' after 4827*tbase, '0' after 4927*tbase, '0' after 5027*tbase, 'H' after 5127*tbase, 'H' after 5227*tbase, -- ADR (0x83)
    '0' after 5327*tbase, --ACK
    '0' after 5427*tbase, '0' after 5527*tbase, 'H' after 5627*tbase, 'H' after 5727*tbase, '0' after 5827*tbase, '0' after 5927*tbase, '0' after 6027*tbase, 'H' after 6127*tbase, -- DATA (0x31)
    'H' after 6227*tbase, --NACK (Recv end)
    '0' after 6327*tbase, --STOP_PREP
    'H' after 6377*tbase; --STOP
 
  tb_error <= '0' when 
    (tb_exp_unit_data_out = tb_unit_data_out)
    and (tb_exp_scheduler_wanted = tb_scheduler_wanted)
    and (tb_exp_SCL = tb_SCL) 
    and (tb_exp_SDA = tb_SDA) 
    and (tb_exp_error_to_host = tb_error_to_host)
    and (tb_exp_error_from_host = tb_error_from_host) else '1';

end TESTBENCH;