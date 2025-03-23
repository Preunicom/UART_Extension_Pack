library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity GPIO_Bank_Unit is
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
end GPIO_Bank_Unit;

architecture Behavioral of GPIO_Bank_Unit is
begin
  REG_OUTP: process(clk)
  begin
    if rising_edge(clk) then   
      if rst = '1' then
        gpio_data_out <= (others => '0');
      else
        if write_en = '1' then
          -- set new output config
          gpio_data_out <= config_in;
        end if;
      end if;
    end if;
  end process;
    
  SYNC_INP: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        values_out <= gpio_data_in;
      else
        -- sync input pins
        values_out <= gpio_data_in;
      end if;
    end if;
  end process;
    
end Behavioral;