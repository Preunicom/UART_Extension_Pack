library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GPIO_Wrapper is
  Generic (
    HOST_DATA_BITS : integer := 8;
    -- IN/OUT_PINS <= HOST_DATA_BITS has to be fullfilled
    -- IN/OUT_PINS >= 1 has to be fullfilled
    IN_PINS : integer := 8;
    OUT_PINS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
    unit_data_in : in STD_LOGIC_VECTOR(HOST_DATA_BITS-1 downto 0);
    unit_data_out : out STD_LOGIC_VECTOR(13 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic;
    gpio_data_in : in STD_LOGIC_VECTOR (IN_PINS-1 downto 0);
    gpio_data_out : out STD_LOGIC_VECTOR (OUT_PINS-1 downto 0)
  );
end GPIO_Wrapper;

architecture Behavioral of GPIO_Wrapper is
  component GPIO_Bank_Unit
    Generic (
      INPUTS : integer := 8;
      OUTPUTS : integer := 8
    );
    Port ( 
      clk, rst : in std_logic;
      write_en : in std_logic;
      config_in : in STD_LOGIC_VECTOR(OUTPUTS-1 downto 0);
      values_out : out STD_LOGIC_VECTOR(INPUTS-1 downto 0);
      gpio_data_in : in STD_LOGIC_VECTOR (INPUTS-1 downto 0);
      gpio_data_out : out STD_LOGIC_VECTOR (OUTPUTS-1 downto 0)
    );
  end component;
  signal write_mode_en : std_logic := '0';
  signal write_values : std_logic_vector(OUT_PINS-1 downto 0);
  signal last_values_read : std_logic_vector(13 downto 0);
  signal values_read : std_logic_vector(13 downto 0) := (others => '0'); -- Extends with zeros if IO_Pins < HOST_DATA_BITS
  signal last_write_enable : std_logic := '0';
  signal last_scheduler_done : std_logic := '0';
begin
  GPIO: GPIO_Bank_Unit generic map(IN_PINS, OUT_PINS) port map(clk, rst, write_mode_en, write_values, values_read(IN_PINS-1 downto 0), gpio_data_in, gpio_data_out);

  OUTPUTS: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        write_mode_en <= '0';
        write_values <= (others => '0');
      else      
        if last_write_enable = '0' and write_en = '1' then
          -- edge of write_en detected
          -- no write/set mode if it won't be overridden
          write_mode_en <= '0';
          if access_mode(0) = '0' then
            -- write/set mode
            write_mode_en <= '1';
            write_values <= unit_data_in(OUT_PINS-1 downto 0);
          end if;
        end if;
      end if;
    end if;
  end process;

  INPUTS: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
      else
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- scheduling finished --> resets request at scheduler
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
        elsif (last_values_read /= values_read) -- Interrupt
          or ((access_mode(0) = '1') and (last_write_enable = '0' and write_en = '1')) then -- new request from host: Get input pin values
            -- Schedule current values
            scheduler_wanted <= '1';
            unit_data_out <= values_read;
          end if;
      end if;
    end if;
  end process;

  EDGE_DETECTION_INPUTS: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_values_read <= (others => '0');
        last_write_enable <= '0';
      else
        -- Check if input pin values have changed
        last_values_read <= values_read;
        -- check if write_en has changed
        last_write_enable <= write_en;
        -- Reset et rising edge of scheduler done
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;
  
end Behavioral;
