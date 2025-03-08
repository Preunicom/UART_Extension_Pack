library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DEMUX is
  Port ( 
    control : in STD_LOGIC_VECTOR (2 downto 0);
    inp : in STD_LOGIC;
    outp_a : out STD_LOGIC;
    outp_b : out STD_LOGIC;
    outp_c : out STD_LOGIC;
    outp_d : out STD_LOGIC;
    outp_e : out STD_LOGIC;
    outp_f : out STD_LOGIC;
    outp_g : out STD_LOGIC;
    outp_h : out STD_LOGIC
  );
end DEMUX;

architecture Behavioral of DEMUX is
begin
  MUX: process(control, inp)
  begin
    outp_a <= '0';
    outp_b <= '0';
    outp_c <= '0';
    outp_d <= '0';
    outp_e <= '0';
    outp_f <= '0';
    outp_g <= '0';
    outp_h <= '0';
    case control is
      when "000" =>
        outp_a <= inp;
      when "001" =>
        outp_b <= inp;
      when "010" => 
        outp_c <= inp;
      when "011" => 
        outp_d <= inp;
      when "100" =>
        outp_e <= inp;
      when "101" =>
        outp_f <= inp;
      when "110" => 
        outp_g <= inp;
      when "111" => 
        outp_h <= inp;
      when others => null;
    end case;
  end process;
end Behavioral;
