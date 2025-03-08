library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX is
  generic (
    WIDTH : integer := 8
  );
  Port ( 
    control : in STD_LOGIC_VECTOR (2 downto 0);
    inp_a : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_b : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_c : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_d : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_e : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_f : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_g : in STD_LOGIC_VECTOR (WIDTH downto 0);
    inp_h : in STD_LOGIC_VECTOR (WIDTH downto 0);
    outp : out STD_LOGIC_VECTOR (WIDTH-1 downto 0)
  );
end MUX;

architecture Behavioral of MUX is
begin
  MUX: process(control, inp_a, inp_b, inp_c, inp_d, inp_e, inp_f, inp_g, inp_h)
  begin
    outp <= (others => '0');
    case control is
      when "000" =>
        outp <= inp_a(WIDTH-1 downto 0);
      when "001" =>
        outp <= inp_b(WIDTH-1 downto 0);
      when "010" => 
        outp <= inp_c(WIDTH-1 downto 0);
      when "011" => 
        outp <= inp_d(WIDTH-1 downto 0);
      when "100" =>
        outp <= inp_e(WIDTH-1 downto 0);
      when "101" =>
        outp <= inp_f(WIDTH-1 downto 0);
      when "110" => 
        outp <= inp_g(WIDTH-1 downto 0);
      when "111" => 
        outp <= inp_h(WIDTH-1 downto 0);
      when others => null;
    end case;
  end process;
end Behavioral;
