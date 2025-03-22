library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.numeric_std.all;
use work.UnitDataArray_Type_PKG.ALL;

entity MUX is
  generic (
    WIDTH : integer := 8
  );
  port (
    control : in  STD_LOGIC_VECTOR(5 downto 0);
    inp     : in unit_data_array;
    outp    : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0)
  );
end entity;

architecture Behavioral of MUX is
begin
  MUX: process (control, inp)
  begin
    outp <= (others => '0');
    outp <= inp(to_integer(unsigned(control)))(WIDTH-1 downto 0);
  end process;
end architecture;
