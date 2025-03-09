library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PriorityScheduler is
  Port ( 
    clk, rst : in STD_LOGIC;
    inp_ressource_ready : in std_logic; --en
    outp_valid : out std_logic;
    control_sig : out std_logic_vector(2 downto 0);
    inp_a : in STD_LOGIC;
    inp_b : in STD_LOGIC;
    inp_c : in STD_LOGIC;
    inp_d : in STD_LOGIC;
    inp_e : in STD_LOGIC;
    inp_f : in STD_LOGIC;
    inp_g : in STD_LOGIC;
    inp_h : in STD_LOGIC;
    outp_a : out STD_LOGIC;
    outp_b : out STD_LOGIC;
    outp_c : out STD_LOGIC;
    outp_d : out STD_LOGIC;
    outp_e : out STD_LOGIC;
    outp_f : out STD_LOGIC;
    outp_g : out STD_LOGIC;
    outp_h : out STD_LOGIC
  );
end PriorityScheduler;

architecture Behavioral of PriorityScheduler is
  signal outputs : std_logic_vector(7 downto 0);
  signal next_outputs : std_logic_vector(7 downto 0);
begin
  outp_a <= outputs(0);
  outp_b <= outputs(1);
  outp_c <= outputs(2);
  outp_d <= outputs(3);
  outp_e <= outputs(4);
  outp_f <= outputs(5);
  outp_g <= outputs(6);
  outp_h <= outputs(7);

  process(inp_ressource_ready, next_outputs, rst)
  begin
    if rst = '1' then
      outputs <= (others => '0');
    elsif inp_ressource_ready = '1' then
      -- set outputs async to next_output if scheduling is pending to save a clock cycle
      outputs <= next_outputs;
    end if;
  end process;
  
  SCHED: process(clk, rst)
  begin
    if rst = '1' then
      next_outputs <= (others => '0');
    elsif rising_edge(clk) then
      if inp_ressource_ready = '1' then
        outp_valid <= '1';
        if inp_a = '1' then
          control_sig <= "000";
          next_outputs <= "00000001";
        elsif inp_b = '1' then
          control_sig <= "001";
          next_outputs <= "00000010";
        elsif inp_c = '1' then
          control_sig <= "010";
          next_outputs <= "00000100";
        elsif inp_d = '1' then
          control_sig <= "011";
          next_outputs <= "00001000";
        elsif inp_e = '1' then
          control_sig <= "100";
          next_outputs <= "00010000";
        elsif inp_f = '1' then
          control_sig <= "101";
          next_outputs <= "00100000";
        elsif inp_g = '1' then
          control_sig <= "110";
          next_outputs <= "01000000";
        elsif inp_h = '1' then
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
