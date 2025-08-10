--! @file
--! @brief Package defining the unit_data_array type.
--! @details This package contains the definition of an array type that stores 64 elements of 14-bit std_logic_vector values.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! Contains the unit_data_array type definition.
package UnitDataArray_Type_PKG is
    --! @typedef unit_data_array
    --! @brief Array type of 64 elements, each 14 bits wide.
    --! @details Index range: 0 to 63, each element is a std_logic_vector(13 downto 0).
    type unit_data_array is array(0 to 63) of std_logic_vector(13 downto 0);
end UnitDataArray_Type_PKG;