--! @file
--! @brief Defines the unit_data_array type for storing multiple unit data entries.
--! @details Provides the `unit_data_array` type as a flexible, unconstrained array of 14-bit `std_logic_vector` elements for ExtPack unit data storage.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package UnitDataArray_Type_PKG is
    --! @typedef unit_data_array
    --! @brief Unconstrained array type of 14-bit `std_logic_vector` elements.
    --!
    --! @details
    --! The index range of the array is specified when the type is used. This makes it
    --! possible to adapt the size of the data storage to different design requirements.
    --! Each array element represents one unit's data in 14-bit format which is the maximum length ExtPack can work with.
    type unit_data_array is array (natural range <>) of std_logic_vector(13 downto 0);
end UnitDataArray_Type_PKG;