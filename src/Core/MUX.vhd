--! @file
--! @brief 64:1 MUX with select for choosing the unit to get the data und unit number from

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;
use work.UnitDataArray_Type_PKG.ALL;

--! Extracts the data of one unit of the input unit data vector and sets it to the output as well as the matching unit number.
entity MUX is
  generic (
    WIDTH : integer := 8 --! Amount of used bits of one std_logic_vector in the unit_data_array.
  );
  port (
    clk           : in std_logic; --! The clock signal.
    rst           : in std_logic; --! The reset signal.
    control       : in  STD_LOGIC_VECTOR(5 downto 0); --! Control signal to choose the unit to extract the data from.
    control_valid : in std_logic; --! Enable signal for the control signal.
    inp           : in unit_data_array; --! The input unit data as array (0...63) of vector of std_logic_vector(0...13)
    outp          : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0); --! The chosen extracted unit data.
    mux_unit_number_out : out std_logic_vector(5 downto 0); --! The number of the unit the data was extracted from.
    outp_valid    : out std_logic --! Enable for outp and mux_unit_number_out signals.
  );
end entity;

--! @brief Architecture definition of the MUX.
architecture Behavioral of MUX is
begin

  --! @brief Extracts the unit data chosen by the control signal of the unit data input vector and sets the chosen unit number as output.
  --! @details Synchronous process with sync reset to extract the chosen unit data and the unit number.  
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
