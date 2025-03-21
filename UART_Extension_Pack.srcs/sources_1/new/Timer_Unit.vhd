library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity Timer_Unit is
  generic (
    WIDTH : integer := 8
  );
  port (
    clk, rst : in std_logic;
    en : in std_logic;
    prescale_factor_write_en : in std_logic;
    prescale_factor : in std_logic_vector(WIDTH-1 downto 0);
    start_value_write_en : in std_logic;
    start_value : in std_logic_vector(WIDTH-1 downto 0);
    restart_timer : in std_logic;
    is_timer_end : out std_logic
  );
end entity;

architecture Behavioral of Timer_Unit is
  signal timer_counter_prescaled : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal timer_counter_non_prescaled : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal start_value_int : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal is_timer_end_value : unsigned(WIDTH-1 downto 0) := (others => '1');
  signal is_timer_end_prescaled : std_logic :='0';
  signal is_timer_end_non_prescaled : std_logic :='0';
  signal prescale_factor_int : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal prescale_counter : integer := 1;
  signal clk_prescaled_intern : std_logic := '0';
  signal timer_rst : std_logic := '0';

  signal en_int : std_logic := '0';
begin

  -- Resets timer if unit is reseted or timer is reseted
  timer_rst <= rst or restart_timer;

  REG: process(clk, rst)
  begin
    if rst = '1' then
      prescale_factor_int <= (others => '0');
      start_value_int <= (others => '0');
    elsif rising_edge(clk) then
      if prescale_factor_write_en = '1' then
        -- Save new prescale factor
        prescale_factor_int <= prescale_factor;
      end if;
      if start_value_write_en = '1' then
        -- Save new start value
        start_value_int <= start_value;
      end if;
    end if;
  end process;

  -- As the 0xFF start value makes problems because it does not have edges in the interrupt output we make them with the enable
  --> We force the signal to 0 for the second half of the clk cycle of the currently used clock
  ENABLE: process(en, clk, clk_prescaled_intern, prescale_factor_int)
  begin
    if (to_integer(unsigned(prescale_factor_int)) <= 1) then 
      en_int <= (en and clk);
    else
      en_int <= (en and clk_prescaled_intern);
    end if;
  end process;

  TIMER_END: process(en_int, is_timer_end_non_prescaled, is_timer_end_prescaled)
  begin
    if en_int = '1' then
      -- Triggers timer end if timer is enabled
      -- Only one of the two timer types is enabled
      is_timer_end <= is_timer_end_prescaled or is_timer_end_non_prescaled;
    else 
      -- timer not enabled
      is_timer_end <= '0';
    end if;
  end process;

  PRESCALER: process (clk, rst)
  begin
    if rst = '1' then
      clk_prescaled_intern <= '0';
      prescale_counter <= 1;
    elsif rising_edge(clk) then
      prescale_counter <= prescale_counter + 1;
      clk_prescaled_intern <= clk_prescaled_intern;
      -- Half of factor because process is only with rising edge triggered
      if prescale_counter >= (to_integer(unsigned(prescale_factor_int)) / 2) then
        clk_prescaled_intern <= clk_prescaled_intern nand clk_prescaled_intern;
        prescale_counter <= 1;
      end if;
    end if;
  end process;

  -- Counts on prescaled clock if prescale_factor is greater then 1
  TIMER_PRESCALED: process(clk_prescaled_intern, timer_rst)
  begin
    if timer_rst = '1' then
      timer_counter_prescaled <= unsigned(start_value_int);
      is_timer_end_prescaled <= '0';
    elsif rising_edge(clk_prescaled_intern) then
      is_timer_end_prescaled <= '0';
      if (to_integer(unsigned(prescale_factor_int)) > 1) then
        -- prescaled timer is choosen
        timer_counter_prescaled <= timer_counter_prescaled + 1;
        if timer_counter_prescaled = is_timer_end_value then
          -- timer overflow --> Interrupt
          is_timer_end_prescaled <= '1';
          timer_counter_prescaled <= unsigned(start_value_int);
        end if;
      end if;
    end if;
  end process;

  -- Counts on prescaled clock if prescale_factor is 0 or 1
  TIMER_NON_PRESCALED: process(clk, timer_rst)
  begin
    if timer_rst = '1' then
      timer_counter_non_prescaled <= unsigned(start_value_int);
      is_timer_end_non_prescaled <= '0';
    elsif rising_edge(clk) then
      is_timer_end_non_prescaled <= '0';
      if (to_integer(unsigned(prescale_factor_int)) <= 1) then
        -- non prescaled timer is choosen
        timer_counter_non_prescaled <= timer_counter_non_prescaled + 1;
        if timer_counter_non_prescaled = is_timer_end_value then         
          -- timer overflow --> Interrupt
          is_timer_end_non_prescaled <= '1';
          timer_counter_non_prescaled <= unsigned(start_value_int);
        end if;
      end if;
    end if;
  end process;
  
end architecture;
