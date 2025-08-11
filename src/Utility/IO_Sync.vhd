--! @file
--! @brief Input-output synchronization for std_logic signals.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! Synchronizes an std_logic signal to the clk signal to reduce metastability. 
entity IO_Sync is
  Port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    async_in : in std_logic; --! Asynchronous input signal.
    sync_out : out std_logic := '0' --! Synchronized output signal.
  );
end IO_Sync;

--! Architecture implementing a two-stage synchronizer to reduce metastability.
architecture Behavioral of IO_Sync is
  signal metastable_reg : std_logic := '0';
begin

  --! Two-stage synchronizer process triggered on the rising clock edge.
  SYNCRONIZER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sync_out <= '0';
        metastable_reg <= '0';
      else
        -- Two flip-flops to reduce metastability.
        metastable_reg <= async_in;
        sync_out <= metastable_reg;
      end if;
    end if;
  end process;

end Behavioral;
