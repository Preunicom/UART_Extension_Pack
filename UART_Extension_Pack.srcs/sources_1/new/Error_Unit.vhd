library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Error_Unit is
  Generic (
    HOST_DATA_BITS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0); -- unused
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
    unit_data_out : out std_logic_vector(13 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic
  );
end Error_Unit;

architecture Behavioral of Error_Unit is

begin


end Behavioral;
