library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PriorityScheduler is
  Port ( 
    clk, rst : in STD_LOGIC;
    inp_ressource_ready : in std_logic; --en
    outp_valid : out std_logic;
    control_sig : out std_logic_vector(2 downto 0);
    inp : in std_logic_vector(7 downto 0);
    outp : out std_logic_vector(7 downto 0)
  );
end PriorityScheduler;

architecture Behavioral of PriorityScheduler is
  -- outputs signalizes the unit that their scheduled data was sent
  signal next_outputs : std_logic_vector(7 downto 0);
begin

  process(inp_ressource_ready, next_outputs, rst)
  begin
    if rst = '1' then
      outp <= (others => '0');
    elsif inp_ressource_ready = '1' then
      -- set outputs async to next_output if scheduling is pending to save a clock cycle
      outp <= next_outputs;
    end if;
  end process;
  
  SCHED: process(clk, rst)
  begin
    if rst = '1' then
      next_outputs <= (others => '0');
    elsif rising_edge(clk) then
      if inp_ressource_ready = '1' then
        -- scheduling next data (prio is: a > b > ... > h)
        outp_valid <= '1';
        if inp(0) = '1' then
          control_sig <= "000";
          next_outputs <= "00000001";
        elsif inp(1) = '1' then
          control_sig <= "001";
          next_outputs <= "00000010";
        elsif inp(2) = '1' then
          control_sig <= "010";
          next_outputs <= "00000100";
        elsif inp(3) = '1' then
          control_sig <= "011";
          next_outputs <= "00001000";
        elsif inp(4) = '1' then
          control_sig <= "100";
          next_outputs <= "00010000";
        elsif inp(5) = '1' then
          control_sig <= "101";
          next_outputs <= "00100000";
        elsif inp(6) = '1' then
          control_sig <= "110";
          next_outputs <= "01000000";
        elsif inp(7) = '1' then
          control_sig <= "111";
          next_outputs <= "10000000";
        else
          outp_valid <= '0';
          control_sig <= "000";
          next_outputs <= "00000000";
        end if;
      end if;
    end if;
  end process;

end Behavioral;
