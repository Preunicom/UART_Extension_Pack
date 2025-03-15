library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DEMUX is
  Port ( 
    control : in STD_LOGIC_VECTOR (2 downto 0);
    inp : in STD_LOGIC;
    outp : out STD_LOGIC_VECTOR(7 downto 0)
  );
end DEMUX;

architecture Behavioral of DEMUX is
begin
  MUX: process(control, inp)
  begin
    outp <= (others => '0');
    case control is
      when "000" =>
        outp(0) <= inp;
      when "001" =>
        outp(1) <= inp;
      when "010" => 
        outp(2) <= inp;
      when "011" => 
        outp(3) <= inp;
      when "100" =>
        outp(4) <= inp;
      when "101" =>
        outp(5) <= inp;
      when "110" => 
        outp(6) <= inp;
      when "111" => 
        outp(7) <= inp;
      when others => null;
    end case;
  end process;
end Behavioral;
