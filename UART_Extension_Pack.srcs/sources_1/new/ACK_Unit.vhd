library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity ACK_Unit is
  Generic (
    HOST_DATA_BITS : integer := 8;
    ACK_UNIT_NUMBER : integer := 2
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
    unit_number : in std_logic_vector(5 downto 0)
  );
end ACK_Unit;

architecture Behavioral of ACK_Unit is
  signal last_scheduler_done : std_logic := '0';
  signal enable_ack : std_logic := '0';
  constant unit_data_out_prefix : std_logic_vector(13 downto HOST_DATA_BITS) := (others => '0');
  signal scheduling_active : std_logic := '0';
  signal write_en_delayed : std_logic := '0'; -- Used because unit data in is delayed by DEMUX by 1 and write_en is taken directly from Decoder
begin

  ACKNOWLEDGE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        enable_ack <= '0';
        scheduling_active <= '0';
      else  
        error_to_host <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- scheduling finished --> resets request at scheduler
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        end if;
        if write_en_delayed = '1' then
          -- new data received by ExtPack
          if enable_ack = '1' then
            -- unit is active --> Send received message back
            scheduler_wanted <= '1';
            unit_data_out <= unit_data_out_prefix & unit_data_in;
            scheduling_active <= '1';
            if scheduling_active = '1' then
              -- Overwriting last ACK package -> Error
              error_to_host <= '1';
            end if;
          end if;
          if to_integer(unsigned(unit_number)) = ACK_UNIT_NUMBER then
            -- command to ACK Unit
            if unsigned(unit_data_in) = 0 then
              enable_ack <= '0';
            else
              enable_ack <= '1';
              scheduler_wanted <= '1';
              unit_data_out <= unit_data_out_prefix & unit_data_in;
              scheduling_active <= '1';
              if scheduling_active = '1' then
                -- Overwriting last ACK package -> Error
                error_to_host <= '1';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  REG: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_scheduler_done <= '0';
        write_en_delayed <= '0';
      else
        write_en_delayed <= write_en;
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;

-- TODO: In Main Unit TB test case erstellen