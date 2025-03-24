library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DEMUX is
  Generic(
    DATA_BITS : integer := 8
  );
  Port ( 
    clk, rst : in std_logic;
    control : in STD_LOGIC_VECTOR (5 downto 0);
    inp_en : in STD_LOGIC;
    inp_data : in std_logic_vector(DATA_BITS-1 downto 0);
    outp_en : out STD_LOGIC_VECTOR(63 downto 0);
    outp_data : out std_logic_vector(DATA_BITS-1 downto 0)
  );
end DEMUX;

architecture Behavioral of DEMUX is
begin
  MUX: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        outp_en <= (others => '0');
        outp_data <= (others => '0');
      else
        outp_en <= (others => '0');
        -- Set the control bit of outp to the inp value
        outp_en(to_integer(unsigned(control))) <= inp_en;
        outp_data <= inp_data;
      end if;
    end if;
  end process;
end Behavioral;
