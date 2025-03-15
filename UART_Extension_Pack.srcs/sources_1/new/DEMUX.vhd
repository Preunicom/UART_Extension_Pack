library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
    case control is
      when "000000" =>
        outp(0) <= inp;
      when "000001" =>
        outp(1) <= inp;
      when "000010" => 
        outp(2) <= inp;
      when "000011" => 
        outp(3) <= inp;
      when "000100" =>
        outp(4) <= inp;
      when "000101" =>
        outp(5) <= inp;
      when "000110" => 
        outp(6) <= inp;
      when "000111" => 
        outp(7) <= inp;
      when "001000" =>
        outp(8) <= inp;
      when "001001" =>
        outp(9) <= inp;
      when "001010" => 
        outp(10) <= inp;
      when "001011" => 
        outp(11) <= inp;
      when "001100" =>
        outp(12) <= inp;
      when "001101" =>
        outp(13) <= inp;
      when "001110" => 
        outp(14) <= inp;
      when "001111" => 
        outp(15) <= inp;
      when "010000" =>
        outp(16) <= inp;
      when "010001" =>
        outp(17) <= inp;
      when "010010" => 
        outp(18) <= inp;
      when "010011" => 
        outp(19) <= inp;
      when "010100" =>
        outp(20) <= inp;
      when "010101" =>
        outp(21) <= inp;
      when "010110" => 
        outp(22) <= inp;
      when "010111" => 
        outp(23) <= inp;
      when "011000" =>
        outp(24) <= inp;
      when "011001" =>
        outp(25) <= inp;
      when "011010" => 
        outp(26) <= inp;
      when "011011" => 
        outp(27) <= inp;
      when "011100" =>
        outp(28) <= inp;
      when "011101" =>
        outp(29) <= inp;
      when "011110" => 
        outp(30) <= inp;
      when "011111" => 
        outp(31) <= inp;
      when "100000" =>
        outp(32) <= inp;
      when "100001" =>
        outp(33) <= inp;
      when "100010" => 
        outp(34) <= inp;
      when "100011" => 
        outp(35) <= inp;
      when "100100" =>
        outp(36) <= inp;
      when "100101" =>
        outp(37) <= inp;
      when "100110" => 
        outp(38) <= inp;
      when "100111" => 
        outp(39) <= inp;
      when "101000" =>
        outp(40) <= inp;
      when "101001" =>
        outp(41) <= inp;
      when "101010" => 
        outp(42) <= inp;
      when "101011" => 
        outp(43) <= inp;
      when "101100" =>
        outp(44) <= inp;
      when "101101" =>
        outp(45) <= inp;
      when "101110" => 
        outp(46) <= inp;
      when "101111" => 
        outp(47) <= inp;
      when "110000" =>
        outp(48) <= inp;
      when "110001" =>
        outp(49) <= inp;
      when "110010" => 
        outp(50) <= inp;
      when "110011" => 
        outp(51) <= inp;
      when "110100" =>
        outp(52) <= inp;
      when "110101" =>
        outp(53) <= inp;
      when "110110" => 
        outp(54) <= inp;
      when "110111" => 
        outp(55) <= inp;
      when "111000" =>
        outp(56) <= inp;
      when "111001" =>
        outp(57) <= inp;
      when "111010" => 
        outp(58) <= inp;
      when "111011" => 
        outp(59) <= inp;
      when "111100" =>
        outp(60) <= inp;
      when "111101" =>
        outp(61) <= inp;
      when "111110" => 
        outp(62) <= inp;
      when "111111" => 
        outp(63) <= inp;
      when others => null;
    end case;
  end process;
end Behavioral;
