library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package UnitDataArray_Type_PKG is
    type unit_data_array is array(0 to 63) of std_logic_vector(13 downto 0);
end UnitDataArray_Type_PKG;