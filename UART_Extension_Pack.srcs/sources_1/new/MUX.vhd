library IEEE;
  use IEEE.STD_LOGIC_1164.all;

entity MUX is
  generic (
    WIDTH : integer := 8
  );
  port (
    control : in  STD_LOGIC_VECTOR(5 downto 0);
    inp_U00 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U01 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U02 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U03 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U04 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U05 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U06 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U07 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U08 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U09 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U10 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U11 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U12 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U13 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U14 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U15 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U16 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U17 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U18 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U19 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U20 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U21 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U22 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U23 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U24 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U25 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U26 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U27 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U28 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U29 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U30 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U31 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U32 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U33 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U34 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U35 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U36 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U37 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U38 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U39 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U40 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U41 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U42 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U43 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U44 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U45 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U46 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U47 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U48 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U49 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U50 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U51 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U52 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U53 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U54 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U55 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U56 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U57 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U58 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U59 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U60 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U61 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U62 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    inp_U63 : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    outp    : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0)
  );
end entity;

architecture Behavioral of MUX is
begin
  MUX: process (control, inp_U00, inp_U01, inp_U02, inp_U03, inp_U04, inp_U05, inp_U06, inp_U07, inp_U08, inp_U09, inp_U10, inp_U11, inp_U12, inp_U13, inp_U14, inp_U15, inp_U16, inp_U17, inp_U18, inp_U19, inp_U20, inp_U21, inp_U22, inp_U23, inp_U24, inp_U25, inp_U26, inp_U27, inp_U28, inp_U29, inp_U30, inp_U31, inp_U32, inp_U33, inp_U34, inp_U35, inp_U36, inp_U37, inp_U38, inp_U39, inp_U40, inp_U41, inp_U42, inp_U43, inp_U44, inp_U45, inp_U46, inp_U47, inp_U48, inp_U49, inp_U50, inp_U51, inp_U52, inp_U53, inp_U54, inp_U55, inp_U56, inp_U57, inp_U58, inp_U59, inp_U60, inp_U61, inp_U62, inp_U63)
  begin
    outp <= (others => '0');
    case control is
      when "000000" =>
        outp <= inp_U00;
      when "000001" =>
        outp <= inp_U01;
      when "000010" =>
        outp <= inp_U02;
      when "000011" =>
        outp <= inp_U03;
      when "000100" =>
        outp <= inp_U04;
      when "000101" =>
        outp <= inp_U05;
      when "000110" =>
        outp <= inp_U06;
      when "000111" =>
        outp <= inp_U07;
      when "001000" =>
        outp <= inp_U08;
      when "001001" =>
        outp <= inp_U09;
      when "001010" =>
        outp <= inp_U10;
      when "001011" =>
        outp <= inp_U11;
      when "001100" =>
        outp <= inp_U12;
      when "001101" =>
        outp <= inp_U13;
      when "001110" =>
        outp <= inp_U14;
      when "001111" =>
        outp <= inp_U15;
      when "010000" =>
        outp <= inp_U16;
      when "010001" =>
        outp <= inp_U17;
      when "010010" =>
        outp <= inp_U18;
      when "010011" =>
        outp <= inp_U19;
      when "010100" =>
        outp <= inp_U20;
      when "010101" =>
        outp <= inp_U21;
      when "010110" =>
        outp <= inp_U22;
      when "010111" =>
        outp <= inp_U23;
      when "011000" =>
        outp <= inp_U24;
      when "011001" =>
        outp <= inp_U25;
      when "011010" =>
        outp <= inp_U26;
      when "011011" =>
        outp <= inp_U27;
      when "011100" =>
        outp <= inp_U28;
      when "011101" =>
        outp <= inp_U29;
      when "011110" =>
        outp <= inp_U30;
      when "011111" =>
        outp <= inp_U31;
      when "100000" =>
        outp <= inp_U32;
      when "100001" =>
        outp <= inp_U33;
      when "100010" =>
        outp <= inp_U34;
      when "100011" =>
        outp <= inp_U35;
      when "100100" =>
        outp <= inp_U36;
      when "100101" =>
        outp <= inp_U37;
      when "100110" =>
        outp <= inp_U38;
      when "100111" =>
        outp <= inp_U39;
      when "101000" =>
        outp <= inp_U40;
      when "101001" =>
        outp <= inp_U41;
      when "101010" =>
        outp <= inp_U42;
      when "101011" =>
        outp <= inp_U43;
      when "101100" =>
        outp <= inp_U44;
      when "101101" =>
        outp <= inp_U45;
      when "101110" =>
        outp <= inp_U46;
      when "101111" =>
        outp <= inp_U47;
      when "110000" =>
        outp <= inp_U48;
      when "110001" =>
        outp <= inp_U49;
      when "110010" =>
        outp <= inp_U50;
      when "110011" =>
        outp <= inp_U51;
      when "110100" =>
        outp <= inp_U52;
      when "110101" =>
        outp <= inp_U53;
      when "110110" =>
        outp <= inp_U54;
      when "110111" =>
        outp <= inp_U55;
      when "111000" =>
        outp <= inp_U56;
      when "111001" =>
        outp <= inp_U57;
      when "111010" =>
        outp <= inp_U58;
      when "111011" =>
        outp <= inp_U59;
      when "111100" =>
        outp <= inp_U60;
      when "111101" =>
        outp <= inp_U61;
      when "111110" =>
        outp <= inp_U62;
      when "111111" =>
        outp <= inp_U63;
      when others => null;
    end case;
  end process;
end architecture;
