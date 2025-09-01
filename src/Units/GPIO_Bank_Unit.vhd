--! @file
--! @brief GPIO bank unit for reading input pins and setting output pins.
--! @details Provides readback of input GPIO pins and writeable configuration of output pins.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! \defgroup UNIT ExtPack units
--! @brief Standard units of ExtPack.
--! @{

--! Updates GPIO outputs on write enable and reads GPIO inputs at change or request.
entity GPIO_Bank_Unit is
--! @}
  Generic (
    INPUTS : integer := 8; --! Number of input GPIO pins.
    OUTPUTS : integer := 8 --! Number of output GPIO pins.
  );
  Port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal. (active high)
    write_en : in std_logic; --! Enable signal for the config_in signal.
    config_in : in STD_LOGIC_VECTOR(OUTPUTS-1 downto 0); --! New output configuration bits.
    values_out : out STD_LOGIC_VECTOR(INPUTS-1 downto 0); --! Latched state of input pins.
    gpio_data_in : in STD_LOGIC_VECTOR (INPUTS-1 downto 0); --! Current state of input pins.
    gpio_data_out : out STD_LOGIC_VECTOR (OUTPUTS-1 downto 0) --! Driven output pins.
  );
end GPIO_Bank_Unit;

--! Architecture implementing synchronous output register update and input pin sampling.
architecture Behavioral of GPIO_Bank_Unit is
begin

  values_out <= gpio_data_in;

  --! Output register process: updates gpio_data_out when write_en is asserted.
  REG_OUTP: process(clk)
  begin
    if rising_edge(clk) then   
      if rst = '1' then
        gpio_data_out <= (others => '0');
      else
        if write_en = '1' then
          -- Set new output configuration.
          gpio_data_out <= config_in;
        end if;
      end if;
    end if;
  end process;
    
end Behavioral;