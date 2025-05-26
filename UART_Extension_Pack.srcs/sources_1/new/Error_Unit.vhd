library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Error_Unit is
  Generic (
    HOST_DATA_BITS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic; -- unused
    access_mode : in std_logic_vector(1 downto 0); -- unused
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); -- unused
    unit_data_out : out std_logic_vector(13 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic;
    error_to_host : out std_logic := '0'; -- unused
    error_from_host : out std_logic := '0'; -- unused
    units_error_to_host : in std_logic_vector(63 downto 0);
    decoder_error : in std_logic;
    units_error_from_host : in std_logic_vector(63 downto 0)
  );
end Error_Unit;

architecture Behavioral of Error_Unit is
  signal last_scheduler_done : std_logic := '0';
  signal is_error_present_to_host : std_logic := '0';
  signal is_error_present_from_host : std_logic := '0';
  signal is_error_of_decoder_present : std_logic := '0';
  signal rst_errors_valid : std_logic := '0';
  signal last_rst_errors_valid_set : std_logic := '0';
  signal suffix : std_logic_vector(13 downto 3) := (others => '0');
begin

  ERROR_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        is_error_present_to_host <= '0';
        is_error_present_from_host <= '0';
        is_error_of_decoder_present <= '0';
      else
        if rst_errors_valid = '1' then
          is_error_present_to_host <= '0';
          is_error_present_from_host <= '0';
          is_error_of_decoder_present <= '0';
        end if;
        if unsigned(units_error_from_host) > 0 then
          is_error_present_from_host <= '1';
        end if;
        if unsigned(units_error_to_host) > 0 then
          is_error_present_to_host <= '1';
        end if;
        if decoder_error = '1' then
          is_error_of_decoder_present <= '1';
        end if;
      end if;
    end if;
  end process;

  SCHEDULE_ERROR: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        rst_errors_valid <= '0';
        last_rst_errors_valid_set <= '0';
      else
        rst_errors_valid <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- scheduling finished
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          rst_errors_valid <= '1';
          last_rst_errors_valid_set <= '1';
        elsif last_rst_errors_valid_set = '1' then
          -- Need one clock cycle to reset signals
          last_rst_errors_valid_set <= '0';
        elsif (is_error_of_decoder_present = '1') or (is_error_present_from_host = '1') or (is_error_present_to_host = '1') then
          -- Send info of error via UART to host
          scheduler_wanted <= '1';
          unit_data_out <= suffix & is_error_present_from_host & is_error_present_to_host & is_error_of_decoder_present;
        end if;
      end if;
    end if;
  end process;

  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_scheduler_done <= '0';
      else
        -- Reset et rising edge of scheduler done
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;
