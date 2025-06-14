library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity I2C_Wrapper is
  Generic (
    HOST_DATA_BITS : integer := 8;
    -- IN_FREQ_HZ has to be minimum 4*I2C_FREQ_HZ
    IN_FREQ_HZ : integer := 12000000;
    I2C_FREQ_HZ : integer := 100000
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0); -- unused
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
    unit_data_out : out std_logic_vector(13 downto 0);
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic;
    error_to_host : out std_logic := '0';
    error_from_host : out std_logic := '0';
    SCL : inout std_logic;
    SDA : inout std_logic
  );
end I2C_Wrapper;

architecture Behavioral of I2C_Wrapper is
  component I2C_Unit
    generic(
      -- IN_FREQ_HZ has to be minimum 4*OUT_FREQ_HZ
      IN_FREQ_HZ  : integer := 12000000;
      I2C_FREQ_HZ : integer := 100000
    );
    port(
      clk, rst : in std_logic;
      write_en : in std_logic;
      adr : in std_logic_vector(6 downto 0);
      mode_recv : in std_logic;
      send_data : in std_logic_vector(7 downto 0);
      data_saved : out std_logic;
      recv_data : out std_logic_vector(7 downto 0);
      recv_data_valid : out std_logic;
      error : out std_logic;
      SCL : inout std_logic;
      SDA : inout std_logic
    );
  end component;

  signal last_write_enable : std_logic := '0';
  signal last_scheduler_done : std_logic := '0';
  signal scheduling_active : std_logic := '0';

  signal unit_data_in_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller I2C data vector with zeros
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller I2C data vector with zeros

  signal I2C_write_en : std_logic := '0';
  signal current_partner_adr : std_logic_vector(6 downto 0) := (others => '0');
  signal I2C_ready : std_logic;
  signal I2C_mode_recv : std_logic;

  signal last_I2C_data_saved : std_logic;
  signal I2C_data_saved : std_logic;

  signal last_recv_data_valid : std_logic;
  signal recv_data_valid : std_logic;

  signal error_I2C_not_ready : std_logic := '0';
  signal error_I2C_NACK : std_logic := '0';

begin
  I2C: I2C_Unit generic map(IN_FREQ_HZ, I2C_FREQ_HZ) port map(clk, rst, I2C_write_en, current_partner_adr, I2C_mode_recv, unit_data_in_buffer(7 downto 0), I2C_data_saved, unit_data_out_buffer(7 downto 0), recv_data_valid, error_I2C_NACK, SCL, SDA);

  I2C_COMM: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        error_I2C_not_ready <= '0';
        unit_data_in_buffer(HOST_DATA_BITS-1 downto 0) <= (others => '0');
        I2C_write_en <= '0';
        I2C_mode_recv <= '0';
        I2C_ready <= '1';
        current_partner_adr <= (others => '0');
      else      
        error_I2C_not_ready <= '0';
        if last_I2C_data_saved = '0' and I2C_data_saved = '1' then
          -- Data was saved
          I2C_write_en <= '0';
          I2C_ready <= '1';
        end if;
        if last_write_enable = '0' and write_en = '1' then
          -- edge of write_en detected
          if access_mode(0) = '1' then
            -- set current partner address (access mode 01/11)
            current_partner_adr <= unit_data_in(6 downto 0);
          else
            if I2C_ready = '1' then
              unit_data_in_buffer(HOST_DATA_BITS-1 downto 0) <= unit_data_in;
              I2C_write_en <= '1';
              I2C_ready <= '0';
              if access_mode(1) = '1' then
                -- receive data (access mode 10)
                I2C_mode_recv <= '1';
              else
                -- send data (access mode 00)
                I2C_mode_recv <= '0';
              end if;
            else
              -- throw error (I2C not ready)
              error_I2C_not_ready <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  RECEIVE: process(clk)
  begin
    if rising_edge(clk) then
      if rst ='1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        error_to_host <= '0';
        scheduling_active <= '0';
      else
        error_to_host <= '0';
        if (last_scheduler_done = '0' and scheduler_done = '1') then
          -- scheduling finished --> resets request at scheduler
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        elsif last_recv_data_valid = '0' and recv_data_valid = '1' then
          -- New I2C data available
          if scheduling_active = '1' then
            -- Overwriting last received I2C package -> Error
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out <= unit_data_out_buffer;
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;

  ERR: process(clk)
	begin
    if rising_edge(clk) then
      if rst = '1' then
        error_from_host <= '0';
      else
        error_from_host <= error_I2C_not_ready or error_I2C_NACK;
      end if;
    end if;
  end process;

  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_enable <= '0';
        last_I2C_data_saved <= '0';
        last_scheduler_done <= '0';
        last_recv_data_valid <= '0';
      else
        last_write_enable <= write_en;
        last_scheduler_done <= scheduler_done;
        last_I2C_data_saved <= I2C_data_saved;
        last_recv_data_valid <= recv_data_valid;
      end if;
    end if;
  end process;


end Behavioral;
