library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.std_logic_unsigned.all;

entity Timer_Wrapper is
  generic (
    HOST_DATA_BITS : integer := 8
  );
  port (
    clk, rst         : in  STD_LOGIC;
    write_en         : in  std_logic;
    access_mode      : in  std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
    unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
    unit_data_out    : out STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done   : in  std_logic
  );
end entity;

architecture Behavioral of Timer_Wrapper is
  component Timer_Unit
    generic (
      WIDTH : integer := 8
    );
    port (
      clk, rst                 : in  std_logic;
      en                       : in  std_logic;
      prescale_factor_write_en : in  std_logic;
      prescale_factor          : in  std_logic_vector(WIDTH - 1 downto 0);
      start_value_write_en     : in  std_logic;
      start_value              : in  std_logic_vector(WIDTH - 1 downto 0);
      restart_timer            : in  std_logic;
      is_timer_end             : out std_logic
    );
  end component;
  signal timer_active_int             : std_logic := '0';
  signal prescale_factor_write_en_int : std_logic := '0';
  signal prescaled_factor_int         : std_logic_vector(HOST_DATA_BITS - 1 downto 0);
  signal start_value_write_en         : std_logic := '0';
  signal start_value_int              : std_logic_vector(HOST_DATA_BITS - 1 downto 0);
  signal restart_timer_int            : std_logic := '0';
  signal is_timer_end_int             : std_logic := '0';
  signal last_is_timer_end            : std_logic := '0';
begin
  TIMER: Timer_Unit generic map (HOST_DATA_BITS) port map (clk, rst, timer_active_int, prescale_factor_write_en_int, prescaled_factor_int, start_value_write_en, start_value_int, restart_timer_int, is_timer_end_int);

  WRITE: process (clk, rst)
  begin
    if rst = '1' then
      restart_timer_int <= '0';
      prescale_factor_write_en_int <= '0';
      start_value_write_en <= '0';
      start_value_int <= (others => '0');
      prescaled_factor_int <= (others => '0');
      timer_active_int <= '0';
    elsif rising_edge(clk) then
      restart_timer_int <= '0';
      prescale_factor_write_en_int <= '0';
      start_value_write_en <= '0';
      start_value_int <= (others => '0');
      prescaled_factor_int <= (others => '0');
      if write_en = '1' then
        -- Received data from host
        case access_mode is
          when "00" =>
            if unit_data_in > 0 then
              -- enable timer
              timer_active_int <= '1';
            else
              -- disable timer
              timer_active_int <= '0';
            end if;
          when "01" =>
            -- restart timer
            restart_timer_int <= '1';
          when "10" =>
            -- set prescale factor
            prescale_factor_write_en_int <= '1';
            prescaled_factor_int <= unit_data_in;
          when "11" =>
            -- set start value
            start_value_write_en <= '1';
            start_value_int <= unit_data_in;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  TIMER_INTERRUPT: process(last_is_timer_end, is_timer_end_int, scheduler_done, rst) 
  begin
    if rst = '1' or scheduler_done = '1' then
      -- reset scheduler_wanted
      scheduler_wanted <= '0';
    elsif is_timer_end_int = '1' and last_is_timer_end = '0' then
      -- timer ended
      scheduler_wanted <= '1';
    end if;
  end process;  

  unit_data_out <= (others => '1');
  
  TIMER_END_EDGE_DETECTION: process(clk, rst)
  begin
    if rst = '1' then
      last_is_timer_end <= '0';
    elsif rising_edge(clk) then
      last_is_timer_end <= is_timer_end_int;
    end if;
  end process;
  
end architecture;
