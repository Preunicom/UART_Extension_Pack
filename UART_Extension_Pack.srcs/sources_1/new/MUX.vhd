library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.numeric_std.all;
use work.UnitDataArray_Type_PKG.ALL;

entity MUX is
  generic (
    WIDTH : integer := 8
  );
  port (
    clk, rst      : in std_logic;
    control       : in  STD_LOGIC_VECTOR(5 downto 0);
    control_valid : in std_logic;
    inp           : in unit_data_array;
    outp          : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    mux_unit_number_out : out std_logic_vector(5 downto 0);
    outp_valid    : out std_logic
  );
end entity;

architecture Behavioral of MUX is
begin
  
  MUX: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Clear outputs
        outp <= (others => '0');
        mux_unit_number_out <= (others => '0');
        outp_valid <= '0';
      else  
        outp <= (others => '0');
        outp <= inp(to_integer(unsigned(control)))(WIDTH-1 downto 0);
        mux_unit_number_out <= control;
        outp_valid <= control_valid;
      end if;
    end if;
  end process;
end architecture;
