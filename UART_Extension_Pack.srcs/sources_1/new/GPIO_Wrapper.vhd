library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GPIO_Wrapper is
  Generic (
    IO_PINS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0); --*0: set, *1: get
    unit_data_in : in STD_LOGIC_VECTOR(IO_PINS-1 downto 0);
    unit_data_out : out STD_LOGIC_VECTOR(IO_PINS-1 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic;
    gpio_data_in : in STD_LOGIC_VECTOR (IO_PINS-1 downto 0);
    gpio_data_out : out STD_LOGIC_VECTOR (IO_PINS-1 downto 0)
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
  signal write_values : std_logic_vector(IO_PINS-1 downto 0);
  signal values_read : std_logic_vector(IO_PINS-1 downto 0);
  signal last_values : std_logic_vector(IO_PINS-1 downto 0);
  signal values_to_scheduler : std_logic_vector(IO_PINS-1 downto 0);
  signal last_enable_write : std_logic := '0';
  signal last_enable_read : std_logic := '0';
begin
  GPIO: GPIO_Bank_Unit generic map(IO_PINS, IO_PINS) port map(clk, rst, write_mode_en, write_values, values_read, gpio_data_in, gpio_data_out);

  OUTPUTS: process(clk, rst)
  begin
    if rst = '1' then
      write_mode_en <= '0';
      write_values <= (others => '0');
      last_enable_write <= '0';
    elsif rising_edge(clk) then
      last_enable_write <= write_en;
      if write_en = '1' and last_enable_write = '0' then
        -- edge of write_en detected
        -- no write/set mode if it won't be overridden
        write_mode_en <= '0';
        if access_mode(0) = '0' then
          -- write/set mode
          write_mode_en <= '1';
          write_values <= unit_data_in;
        end if;
      end if;
    end if;
  end process;

  INPUTS: process(clk, rst)
  begin
    if rst = '1' then
      scheduler_wanted <= '0';
      values_to_scheduler <= (others => '0');
      last_enable_read <= '0';
    elsif rising_edge(clk) then
      last_enable_read <= write_en;
      last_values <= values_read;
      if scheduler_done = '1' then
        -- scheduling finished --> resets demand of scheduler
        scheduler_wanted <= '0';
      end if;
      if (last_values /= values_read) or ((access_mode(0) = '1') and (write_en = '1' and last_enable_read = '0')) then
        -- Interrrupt or edge detected of write_en and read/get mode
        scheduler_wanted <= '1';
        values_to_scheduler <= values_read;
      end if;
    end if;
  end process;

  unit_data_out <= values_to_scheduler;
  
end Behavioral;
