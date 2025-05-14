library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Wrapper is
  Generic (
    HOST_DATA_BITS : integer := 8;
    -- IN_FREQ_HZ has to be minimum 2*SPI_FREQ_HZ
    IN_FREQ_HZ : integer := 12000000;
    SPI_FREQ_HZ : integer := 9600;
    AMOUNT_SLAVES : integer := 1;
    SPI_MODE : integer := 0;
    LEAST_SIG_BIT_FIRST : integer := 0; -- true or false
    DATA_BITS : integer := 8
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
    SCK : out std_logic;
    CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
    MOSI : out std_logic;
    MISO : in std_logic
  );
end SPI_Wrapper;

architecture Behavioral of SPI_Wrapper is
  component SPI_Unit
    Generic (
      -- IN_FREQ_HZ has to be minimum 2*SPI_FREQ_HZ
      IN_FREQ_HZ : integer := 12000000;
      SPI_FREQ_HZ : integer := 9600;
      AMOUNT_SLAVES : integer := 1;
      DATA_BITS : integer := 8;
      SPI_MODE : integer := 0;
      LEAST_SIG_BIT_FIRST : integer := 0 -- true or false
    );
    Port ( 
      clk, rst : in std_logic;
      SCK : out std_logic;
      send_data : in std_logic_vector(DATA_BITS-1 downto 0);
      slave_id : in integer;
      write_en : in std_logic;
      ready : out std_logic;
      MOSI : out std_logic;
      CS : out std_logic_vector(AMOUNT_SLAVES-1 downto 0) := (others => '1');
      received_data : out std_logic_vector(DATA_BITS-1 downto 0);
      new_data_received : out std_logic;
      MISO : in std_logic
    );
  end component;
  signal last_write_enable : std_logic := '0';
  signal last_scheduler_done : std_logic := '0';
  signal scheduling_active : std_logic := '0';
  signal spi_ready : std_logic := '1';
  signal spi_write_en : std_logic := '0';
  signal spi_new_data : std_logic := '0';
  signal last_spi_new_data : std_logic := '0';
  signal current_slave_id : integer := 0;
  signal unit_data_in_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller SPI data vector with zeros
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0'); -- Extends smaller SPI data vector with zeros
begin
  SPI: SPI_Unit generic map(IN_FREQ_HZ, SPI_FREQ_HZ, AMOUNT_SLAVES, DATA_BITS, SPI_MODE, LEAST_SIG_BIT_FIRST) port map(clk, rst, SCK, unit_data_in_buffer(DATA_BITS-1 downto 0), current_slave_id, spi_write_en, spi_ready, MOSI, CS, unit_data_out_buffer(DATA_BITS-1 downto 0), spi_new_data, MISO);

  TRANSMIT: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        current_slave_id <= 0;
        error_from_host <= '0';
        unit_data_in_buffer(HOST_DATA_BITS-1 downto 0) <= (others => '0');
        spi_write_en <= '0';
      else      
        error_from_host <= '0';
        spi_write_en <= '0';
        if last_write_enable = '0' and write_en = '1' then
          -- edge of write_en detected
          -- no write/set mode if it won't be overridden
          if access_mode(0) = '1' then
            -- set current slave id
            if to_integer(unsigned(unit_data_in)) < AMOUNT_SLAVES then
              -- send data
              current_slave_id <= to_integer(unsigned(unit_data_in));
            else
              error_from_host <= '1';
            end if;
          elsif access_mode(0) = '0' then
            -- send data
            if spi_ready = '1' then
              -- send SPI
              unit_data_in_buffer(HOST_DATA_BITS-1 downto 0) <= unit_data_in;
              spi_write_en <= '1';
            else
              -- throw error
              error_from_host <= '1';
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
        elsif last_spi_new_data = '0' and spi_new_data = '1' then
          -- New SPI data available
          if scheduling_active = '1' then
            -- Overwriting last received SPI package -> Error
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out <= unit_data_out_buffer;
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;

  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_write_enable <= '0';
        last_spi_new_data <= '0';
        last_scheduler_done <= '0';
      else
        last_write_enable <= write_en;
        last_scheduler_done <= scheduler_done;
        last_spi_new_data <= spi_new_data;
      end if;
    end if;
  end process;

end Behavioral;
