library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity Timer_Unit is
  generic (
    WIDTH : integer := 8;
    IN_FREQ : integer := 12000000;
    BASE_FREQ : integer := 50000
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
  constant PRESCALE_COUNTER_END : integer := IN_FREQ / BASE_FREQ;
  constant PRESCALE_COUNTER_HALF : integer := IN_FREQ / (2*BASE_FREQ);
  constant is_timer_end_value : unsigned(WIDTH-1 downto 0) := (others => '1');
  signal timer_counter : unsigned(WIDTH-1 downto 0) := (others => '0');
  signal start_value_int : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal prescale_factor_int : std_logic_vector(WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, WIDTH));
  signal prescale_counter : integer := 1;
  signal clk_en_prescaled : std_logic := '0';
  signal timer_rst : std_logic := '0';
begin

  PRESCALER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        clk_en_prescaled <= '0';
        prescale_counter <= (PRESCALE_COUNTER_HALF*(to_integer(unsigned(prescale_factor_int)))) + 2; -- TODO : set 0 & edit TB (same procedure in other units)
      else
        prescale_counter <= prescale_counter + 1;
        clk_en_prescaled <= '0';
        if prescale_counter >= (PRESCALE_COUNTER_END*(to_integer(unsigned(prescale_factor_int)))) then 
          clk_en_prescaled <= '1';
          prescale_counter <= 1;
        end if;
      end if;
    end if;
  end process;

  -- Resets timer if unit is reseted or timer is reseted
  timer_rst <= rst or restart_timer;

  REG: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        start_value_int <= (others => '0');
        prescale_factor_int <= std_logic_vector(to_unsigned(1, WIDTH));
      else
        if prescale_factor_write_en = '1' then
          -- Save new prescale factor
          prescale_factor_int <= prescale_factor; -- TODO: Directly calculate counter end value here and only test it above in prescaler
          if to_integer(unsigned(prescale_factor)) = 0 then
            prescale_factor_int <= std_logic_vector(to_unsigned(1, WIDTH));
          end if;
        end if;
        if start_value_write_en = '1' then
          -- Save new start value
          start_value_int <= start_value;
        end if;
      end if;
    end if;
  end process;

  TIMER_PRESCALED: process(clk)
  begin
    if rising_edge(clk) then
      if timer_rst = '1' then
        timer_counter <= (others => '0');
        is_timer_end <= '0';
      elsif clk_en_prescaled = '1' and en = '1' then
        is_timer_end <= '0';
        if timer_counter = 0 then
          -- Overflow or rst happended last clock cycle
          --> jump to start_value (+1)
          timer_counter <= unsigned(start_value_int) + 1;
        else
          -- Normal counting
          timer_counter <= timer_counter + 1;
        end if;
        -- Timer end OR start value is end value (what means every clock cycle is timer end)
        -- The end value case would be not catched if it would not be an extra condition
        if (timer_counter = is_timer_end_value) or (unsigned(start_value_int) = is_timer_end_value) then
          -- timer overflow 
          --> Interrupt + Reset counter to 0
          is_timer_end <= '1';
          timer_counter <= (others => '0');
        end if;
      else
        is_timer_end <= '0';
      end if;
    end if;
  end process;
  
end architecture;
