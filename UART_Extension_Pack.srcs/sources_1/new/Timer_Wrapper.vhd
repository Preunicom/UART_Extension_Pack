library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.std_logic_unsigned.all;

entity Timer_Wrapper is
  generic (
    HOST_DATA_BITS : integer := 8;
    FPGA_FREQ : integer := 12000000;
    HOST_BAUD : integer := 1000000
  );
  port (
    clk, rst         : in  STD_LOGIC;
    write_en         : in  std_logic;
    access_mode      : in  std_logic_vector(1 downto 0); --00: en, 01: restart, 10: prescale_factor, 11: start_value
    unit_data_in     : in  STD_LOGIC_VECTOR(HOST_DATA_BITS - 1 downto 0);
    unit_data_out    : out STD_LOGIC_VECTOR(13 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done   : in  std_logic;
    error_to_host : out std_logic := '0';
    error_from_host : out std_logic := '0' -- unused
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
  signal start_value_write_en_int     : std_logic := '0';
  signal start_value_int              : std_logic_vector(HOST_DATA_BITS - 1 downto 0);
  signal restart_timer_int            : std_logic := '0';
  signal is_timer_end_int             : std_logic := '0';
  signal last_is_timer_end_int        : std_logic := '0';
  signal clk_prescaled_intern         : std_logic := '0';
  signal prescale_counter             : integer := 1;
  signal last_scheduler_done          : std_logic := '0';
  signal scheduling_active            : std_logic := '0';
begin
  TIMER: Timer_Unit generic map (HOST_DATA_BITS) port map (clk_prescaled_intern, rst, timer_active_int, prescale_factor_write_en_int, prescaled_factor_int, start_value_write_en_int, start_value_int, restart_timer_int, is_timer_end_int);

  -- Prescales the host clock to 1/20 of the host baud rate, as this is the maximum number of interrupts that can be sent via UART in an 8N1 configuration (because 2*10bit (unit number and unit data) per transmission).
  PRESCALE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        clk_prescaled_intern <= '0';
        prescale_counter <= 1;
      else
        prescale_counter <= prescale_counter + 1;
        clk_prescaled_intern <= clk_prescaled_intern;
        -- integer gets truncated in VHDL
        -- Prescales to HOST_BAUD and multiply this value with 20 to get 1/20 of HOST_BAUD as frequency
        if prescale_counter >= (((FPGA_FREQ + HOST_BAUD) / (2 * HOST_BAUD))*20) then
          clk_prescaled_intern <= clk_prescaled_intern nand clk_prescaled_intern;
          prescale_counter <= 1;
        end if;
      end if;
    end if;
  end process;
  
  WRITE: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        restart_timer_int <= '0';
        prescale_factor_write_en_int <= '0';
        start_value_write_en_int <= '0';
        start_value_int <= (others => '0');
        prescaled_factor_int <= (others => '0');
        timer_active_int <= '0';
      else
        restart_timer_int <= '0';
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
              start_value_write_en_int <= '1';
              start_value_int <= unit_data_in;
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process;

  TIMER_INTERRUPT: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        scheduling_active <= '0';
        error_to_host <= '0';
      else
        error_to_host <= '0';
        if last_scheduler_done = '0' and scheduler_done = '1' then
          -- scheduling finished --> resets request at scheduler
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        end if;
        if last_is_timer_end_int = '0' and is_timer_end_int = '1' then
          -- Schedule current interrupt
          if scheduling_active = '1' then
            -- Overwriting last timer interrupt -> Error
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out <= (others => '1');
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;
  
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_is_timer_end_int <= '0';
        last_scheduler_done <= '0';
      else
        last_is_timer_end_int <= is_timer_end_int;
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;
  
end architecture;
