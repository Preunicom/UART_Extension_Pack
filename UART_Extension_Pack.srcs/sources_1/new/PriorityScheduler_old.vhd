library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PriorityScheduler is
  Port ( 
    clk, rst : in STD_LOGIC;
    schedule_next : in std_logic;
    outp_valid : out std_logic;
    control_sig : out std_logic_vector(5 downto 0);
    scheduler_wanted : in std_logic_vector(63 downto 0);
    scheduler_done : out std_logic_vector(63 downto 0)
  );
end PriorityScheduler;

architecture Behavioral of PriorityScheduler is
  -- outputs signalizes the unit that their scheduled data was sent
  signal next_outputs : std_logic_vector(63 downto 0);
begin

  process(schedule_next, next_outputs, rst)
  begin
    if rst = '1' then
      scheduler_done <= (others => '0');
    elsif schedule_next = '1' then
      -- set outputs async to next_output if scheduling is pending to save a clock cycle
      scheduler_done <= next_outputs;
    end if;
  end process;
  
  SCHED: process(clk, rst)
  begin
    if rst = '1' then
      next_outputs <= (others => '0');
    elsif rising_edge(clk) then
      if schedule_next = '1' then
        -- scheduling next data (lower unit number is higher prio)
        outp_valid <= '1';
        next_outputs <= (others => '0');
        if scheduler_wanted(0) = '1' then
          control_sig <= "000000";
          next_outputs(0) <= '1';
        elsif scheduler_wanted(1) = '1' then
          control_sig <= "000001";
          next_outputs(1) <= '1';
        elsif scheduler_wanted(2) = '1' then
          control_sig <= "000010";
          next_outputs(2) <= '1';
        elsif scheduler_wanted(3) = '1' then
          control_sig <= "000011";
          next_outputs(3) <= '1';
        elsif scheduler_wanted(4) = '1' then
          control_sig <= "000100";
          next_outputs(4) <= '1';
        elsif scheduler_wanted(5) = '1' then
          control_sig <= "000101";
          next_outputs(5) <= '1';
        elsif scheduler_wanted(6) = '1' then
          control_sig <= "000110";
          next_outputs(6) <= '1';
        elsif scheduler_wanted(7) = '1' then
          control_sig <= "000111";
          next_outputs(7) <= '1';
        elsif scheduler_wanted(8) = '1' then
          control_sig <= "001000";
          next_outputs(8) <= '1';
        elsif scheduler_wanted(9) = '1' then
          control_sig <= "001001";
          next_outputs(9) <= '1';
        elsif scheduler_wanted(10) = '1' then
          control_sig <= "001010";
          next_outputs(10) <= '1';
        elsif scheduler_wanted(11) = '1' then
          control_sig <= "001011";
          next_outputs(11) <= '1';
        elsif scheduler_wanted(12) = '1' then
          control_sig <= "001100";
          next_outputs(12) <= '1';
        elsif scheduler_wanted(13) = '1' then
          control_sig <= "001101";
          next_outputs(13) <= '1';
        elsif scheduler_wanted(14) = '1' then
          control_sig <= "001110";
          next_outputs(14) <= '1';
        elsif scheduler_wanted(15) = '1' then
          control_sig <= "001111";
          next_outputs(15) <= '1';
        elsif scheduler_wanted(16) = '1' then
          control_sig <= "010000";
          next_outputs(16) <= '1';
        elsif scheduler_wanted(17) = '1' then
          control_sig <= "010001";
          next_outputs(17) <= '1';
        elsif scheduler_wanted(18) = '1' then
          control_sig <= "010010";
          next_outputs(18) <= '1';
        elsif scheduler_wanted(19) = '1' then
          control_sig <= "010011";
          next_outputs(19) <= '1';
        elsif scheduler_wanted(20) = '1' then
          control_sig <= "010100";
          next_outputs(20) <= '1';
        elsif scheduler_wanted(21) = '1' then
          control_sig <= "010101";
          next_outputs(21) <= '1';
        elsif scheduler_wanted(22) = '1' then
          control_sig <= "010110";
          next_outputs(22) <= '1';
        elsif scheduler_wanted(23) = '1' then
          control_sig <= "010111";
          next_outputs(23) <= '1';
        elsif scheduler_wanted(24) = '1' then
          control_sig <= "011000";
          next_outputs(24) <= '1';
        elsif scheduler_wanted(25) = '1' then
          control_sig <= "011001";
          next_outputs(25) <= '1';
        elsif scheduler_wanted(26) = '1' then
          control_sig <= "011010";
          next_outputs(26) <= '1';
        elsif scheduler_wanted(27) = '1' then
          control_sig <= "011011";
          next_outputs(27) <= '1';
        elsif scheduler_wanted(28) = '1' then
          control_sig <= "011100";
          next_outputs(28) <= '1';
        elsif scheduler_wanted(29) = '1' then
          control_sig <= "011101";
          next_outputs(29) <= '1';
        elsif scheduler_wanted(30) = '1' then
          control_sig <= "011110";
          next_outputs(30) <= '1';
        elsif scheduler_wanted(31) = '1' then
          control_sig <= "011111";
          next_outputs(31) <= '1';
        elsif scheduler_wanted(32) = '1' then
          control_sig <= "100000";
          next_outputs(32) <= '1';
        elsif scheduler_wanted(33) = '1' then
          control_sig <= "100001";
          next_outputs(33) <= '1';
        elsif scheduler_wanted(34) = '1' then
          control_sig <= "100010";
          next_outputs(34) <= '1';
        elsif scheduler_wanted(35) = '1' then
          control_sig <= "100011";
          next_outputs(35) <= '1';
        elsif scheduler_wanted(36) = '1' then
          control_sig <= "100100";
          next_outputs(36) <= '1';
        elsif scheduler_wanted(37) = '1' then
          control_sig <= "100101";
          next_outputs(37) <= '1';
        elsif scheduler_wanted(38) = '1' then
          control_sig <= "100110";
          next_outputs(38) <= '1';
        elsif scheduler_wanted(39) = '1' then
          control_sig <= "100111";
          next_outputs(39) <= '1';
        elsif scheduler_wanted(40) = '1' then
          control_sig <= "101000";
          next_outputs(40) <= '1';
        elsif scheduler_wanted(41) = '1' then
          control_sig <= "101001";
          next_outputs(41) <= '1';
        elsif scheduler_wanted(42) = '1' then
          control_sig <= "101010";
          next_outputs(42) <= '1';
        elsif scheduler_wanted(43) = '1' then
          control_sig <= "101011";
          next_outputs(43) <= '1';
        elsif scheduler_wanted(44) = '1' then
          control_sig <= "101100";
          next_outputs(44) <= '1';
        elsif scheduler_wanted(45) = '1' then
          control_sig <= "101101";
          next_outputs(45) <= '1';
        elsif scheduler_wanted(46) = '1' then
          control_sig <= "101110";
          next_outputs(46) <= '1';
        elsif scheduler_wanted(47) = '1' then
          control_sig <= "101111";
          next_outputs(47) <= '1';
        elsif scheduler_wanted(48) = '1' then
          control_sig <= "110000";
          next_outputs(48) <= '1';
        elsif scheduler_wanted(49) = '1' then
          control_sig <= "110001";
          next_outputs(49) <= '1';
        elsif scheduler_wanted(50) = '1' then
          control_sig <= "110010";
          next_outputs(50) <= '1';
        elsif scheduler_wanted(51) = '1' then
          control_sig <= "110011";
          next_outputs(51) <= '1';
        elsif scheduler_wanted(52) = '1' then
          control_sig <= "110100";
          next_outputs(52) <= '1';
        elsif scheduler_wanted(53) = '1' then
          control_sig <= "110101";
          next_outputs(53) <= '1';
        elsif scheduler_wanted(54) = '1' then
          control_sig <= "110110";
          next_outputs(54) <= '1';
        elsif scheduler_wanted(55) = '1' then
          control_sig <= "110111";
          next_outputs(55) <= '1';
        elsif scheduler_wanted(56) = '1' then
          control_sig <= "111000";
          next_outputs(56) <= '1';
        elsif scheduler_wanted(57) = '1' then
          control_sig <= "111001";
          next_outputs(57) <= '1';
        elsif scheduler_wanted(58) = '1' then
          control_sig <= "111010";
          next_outputs(58) <= '1';
        elsif scheduler_wanted(59) = '1' then
          control_sig <= "111011";
          next_outputs(59) <= '1';
        elsif scheduler_wanted(60) = '1' then
          control_sig <= "111100";
          next_outputs(60) <= '1';
        elsif scheduler_wanted(61) = '1' then
          control_sig <= "111101";
          next_outputs(61) <= '1';
        elsif scheduler_wanted(62) = '1' then
          control_sig <= "111110";
          next_outputs(62) <= '1';
        elsif scheduler_wanted(63) = '1' then
          control_sig <= "111111";
          next_outputs(63) <= '1';
        else
          outp_valid <= '0';
          control_sig <= "000000";
        end if;
      end if;
    end if;
  end process;

end Behavioral;