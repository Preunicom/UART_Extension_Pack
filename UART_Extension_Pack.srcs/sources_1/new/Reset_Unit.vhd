library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Reset_Unit is
  Generic (
    HOST_DATA_BITS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0); -- unused
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); 
    unit_data_out : out std_logic_vector(13 downto 0); 
    scheduler_wanted : out std_logic; 
    scheduler_done : in std_logic;
    error_to_host : out std_logic := '0'; -- unused
    error_from_host : out std_logic := '0'; -- unused
    rst_ext_pack : out std_logic := '0'
  );
end Reset_Unit;

architecture Behavioral of Reset_Unit is
  signal rst_cmp_value : std_logic_vector(HOST_DATA_BITS-1 downto 0) := (others => '1');
  signal last_write_enable : std_logic := '0';
  signal last_scheduler_done : std_logic := '0';
  signal rst_triggered : std_logic := '1';
begin

  SET_RST: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rst_ext_pack <= '0';
      else  
        rst_ext_pack <= '0';    
        if last_write_enable = '0' and write_en = '1' then
          -- edge of write_en detected
          if unit_data_in = rst_cmp_value then
            -- send reset request for one clock cycle to main unit
            rst_ext_pack <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  GET_RST: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        -- Reset was triggered
        rst_triggered <= '1';
      else
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- scheduling finished --> resets request at scheduler
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          rst_triggered <= '0';
        elsif rst_triggered = '1' then
          -- Send info of reset via UART to host
          scheduler_wanted <= '1';
          unit_data_out <= (others => '1');
          rst_triggered <= '0';
        end if;
      end if;
    end if;
  end process;

  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_enable <= '0';
        last_scheduler_done <= '0';
      else
        -- check if write_en has changed
        last_write_enable <= write_en;
        -- Reset et rising edge of scheduler done
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;
