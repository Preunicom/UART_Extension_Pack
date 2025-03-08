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
  signal port_register : std_logic_vector(OUTPUTS-1 downto 0) := (others => '0');
begin
    REG: process(clk, rst)
    begin
        if rst = '1' then
            port_register <= (others => '0');
        elsif rising_edge(clk) then   
            if write_en = '1' then
                port_register <= config_in;
            else
                port_register <= port_register;
            end if;
        end if;
    end process;

    gpio_data_out <= port_register;
    
    SYNC: process(clk, rst)
    begin
        if rst = '1' then
            values_out <= gpio_data_in;
        elsif rising_edge(clk) then
            values_out <= gpio_data_in;
        end if;
    end process;
    
end Behavioral;