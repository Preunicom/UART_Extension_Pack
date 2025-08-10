--! @file
--! @brief Input-output synchronization for std_logic_vector signals.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! Synchronizes an std_logic_vector signal to the clk signal to reduce metastability.
entity IO_Sync_Vector is
  Generic(
    len: integer := 2 --! The length of the std_logic_vector
  );
  Port (
    clk : in std_logic; --! The clock signal.
    rst : in std_logic; --! The reset signal.
    async_in : in std_logic_vector(len-1 downto 0); --! Asynchronous input vector.
    sync_out : out std_logic_vector(len-1 downto 0) := (others => '0') --! Synchronized output vector.
  );
end IO_Sync_Vector;

--! Architecture implementing a two-stage synchronizer for vector signals to reduce metastability.
architecture Behavioral of IO_Sync_Vector is
  signal metastable_reg : std_logic_vector(len-1 downto 0) := (others => '0');
begin

  --! Two-stage synchronizer process triggered on the rising clock edge.
  SYNCRONIZER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sync_out <= (others => '0');
        metastable_reg <= (others => '0');
      else
        -- Two flip-flops to reduce metastability.
        metastable_reg <= async_in;
        sync_out <= metastable_reg;
      end if;
    end if;
  end process;

end Behavioral;
