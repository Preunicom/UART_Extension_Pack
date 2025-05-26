library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IO_Sync_Vector is
  Generic(
    len: integer := 2
  );
  Port (
    clk, rst : in std_logic;
    async_in : in std_logic_vector(len-1 downto 0);
    sync_out : out std_logic_vector(len-1 downto 0) := (others => '0')
  );
end IO_Sync_Vector;

architecture Behavioral of IO_Sync_Vector is
  signal metastable_reg : std_logic_vector(len-1 downto 0) := (others => '0');
begin

  SYNCRONIZER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sync_out <= (others => '0');
        metastable_reg <= (others => '0');
      else
        -- 2 flip flops to reduce metastability
        metastable_reg <= async_in;
        sync_out <= metastable_reg;
      end if;
    end if;
  end process;

end Behavioral;
