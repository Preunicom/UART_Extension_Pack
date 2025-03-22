library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DEMUX is
  Port ( 
    control : in STD_LOGIC_VECTOR (5 downto 0);
    inp : in STD_LOGIC;
    outp : out STD_LOGIC_VECTOR(63 downto 0)
  );
end DEMUX;

architecture Behavioral of DEMUX is
begin
  MUX: process(control, inp)
  begin
    outp <= (others => '0');
    outp(to_integer(unsigned(control))) <= inp;
  end process;
end Behavioral;
