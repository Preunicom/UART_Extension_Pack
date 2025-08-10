--! @file
--! @brief SRAM interface unit for ISSI IS61WV5128BLL (512Kx8) asynchronous SRAM.
--! @details Supports single-byte read and write transactions with access-time timing enforcement. Generates tri-state control for the data bus and reports protocol errors.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! \defgroup UNIT ExtPack units
--! @brief Standard units of ExtPack.
--! @{

--! Wraps the IS61WV5128BLL SRAM with a simple read/write handshake and timing control.
entity ISSI_IS61WV5128BLL_SRAM_Unit is
--! @}
  Generic (
    IN_FREQ : integer := 12000000; --! Input clock frequency in Hz.
    ACCESS_TIME_NS : integer := 8 --! SRAM access time in nanoseconds (t_ACC / t_RC).
  );
  Port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    read_en : in std_logic; --! Start a read transaction.
    write_en : in std_logic; --! Start a write transaction.
    adr_in : in unsigned(18 downto 0); --! Byte address (0..2^19-1).
    data_in : in std_logic_vector(7 downto 0); --! Data to write on write transactions.
    data_out : out std_logic_vector(7 downto 0); --! Data read from SRAM.
    data_out_en : out std_logic; --! One-cycle strobe indicating valid `data_out`.
    sram_adr : out std_logic_vector(18 downto 0); --! SRAM address bus.
    sram_data : inout std_logic_vector(7 downto 0); --! Bidirectional SRAM data bus.
    sram_oen : out std_logic := '1'; --! SRAM OE# (active low).
    sram_cen : out std_logic := '1'; --! SRAM CE# (active low).
    sram_wen : out std_logic := '1'; --! SRAM WE# (active low).
    error : out std_logic := '0' --! Error flag: overlapping command during active transaction.
  );
end ISSI_IS61WV5128BLL_SRAM_Unit;

--! Architecture implementing timing control, tri-state management, and a simple FSM for read/write.
architecture Behavioral of ISSI_IS61WV5128BLL_SRAM_Unit is
  --! Number of clock cycles corresponding to ACCESS_TIME_NS at IN_FREQ.
  constant ACCESS_TIMER_END : integer := (ACCESS_TIME_NS * IN_FREQ) / 1000000000;
  --! Counts cycles to enforce minimum access time.
  signal access_time_counter : integer := 0;
  --! Enables the access-time counter during active transactions.
  signal access_time_counter_en : std_logic := '0';
  --! Pulse asserted when the enforced access time has elapsed.
  signal read_write_en : std_logic;
  --! Latched write data (meets t_HZWE by delaying drive).
  signal write_data_reg : std_logic_vector(7 downto 0);
  --! Direction control for data bus: '1' = drive out, '0' = high-Z (read).
  signal sram_data_dir_out : std_logic := '0';
  --! Registered data driven to the SRAM data bus during writes.
  signal sram_data_out : std_logic_vector(7 downto 0);
  --! Sampled data from the SRAM data bus during reads.
  signal sram_data_in : std_logic_vector(7 downto 0);

  --! FSM states for idle, read, write-setup, and write-hold.
  type statetype is (IDLE, READ, WRITE, WRITE_DATA_VALID);
  --! Current FSM state.
  signal state : statetype := IDLE;
begin
  --! Tri-state control: drive data bus only during writes.
  sram_data <=  sram_data_out when sram_data_dir_out = '1' else (others => 'Z');
  --! Sample incoming data bus during reads.
  sram_data_in  <= sram_data;

  --! Main FSM process: sequences read/write operations and enforces access timing.
  READ_WRITE: process(clk)
	begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= IDLE;
        data_out <= (others => '0');
        data_out_en <= '0';
        sram_data_dir_out <= '0';
        sram_data_out <= (others => '0');
        access_time_counter_en <= '0';
        sram_adr <= (others => '0');
        sram_cen <= '1';
        sram_oen <= '1';
        sram_wen <= '1';
        write_data_reg <= (others => '0');
        error <= '0';
      else
        error <= '0';
        data_out_en <= '0';
        data_out <= (others=>'0');
        sram_data_dir_out <= '0';
        case state is
          when IDLE =>
            sram_adr <= (others=>'0');
            sram_cen <= '1';
            sram_oen <= '1';
            sram_wen <= '1';
            if write_en = '1' then
              state <= WRITE;
              sram_adr <= std_logic_vector(adr_in);
              write_data_reg <= data_in; -- Delay write data to satisfy tHZWE.
              sram_cen <= '0';
              sram_oen <= '1';
              sram_wen <= '0';
              access_time_counter_en <= '1';
            elsif read_en = '1' then
              state <= READ;
              sram_adr <= std_logic_vector(adr_in);
              sram_cen <= '0';
              sram_oen <= '0';
              sram_wen <= '1';
              access_time_counter_en <= '1';
            end if;
          when READ =>
            if read_write_en = '1' then
              data_out <= sram_data_in;
              data_out_en <= '1';
              access_time_counter_en <= '0';
              state <= IDLE;
            end if;
             if read_en = '1' or write_en = '1' then
              error <= '1';
            end if;
          when WRITE =>
            -- Hold write data valid until access time elapses.
            if read_write_en = '1' then
              sram_data_dir_out <= '1';
              sram_data_out <= write_data_reg;
              access_time_counter_en <= '1';
              state <= WRITE_DATA_VALID;
            end if;
            if read_en = '1' or write_en = '1' then
              error <= '1';
            end if;
          when WRITE_DATA_VALID =>
            sram_data_dir_out <= '1';
            sram_data_out <= write_data_reg;
            if read_write_en = '1' then
              access_time_counter_en <= '0';
              state <= IDLE;
            end if;
            if read_en = '1' or write_en = '1' then
              error <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;

  --! Access-time counter: generates read_write_en after the required number of cycles.
  ACCESS_TIME_TIMER: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then 
        access_time_counter <= 0;
        read_write_en <= '0';
      else
        read_write_en <= '0';
        if access_time_counter_en = '1' then
          access_time_counter <= access_time_counter + 1;
          if access_time_counter >= ACCESS_TIMER_END then
            -- Signal that the minimum access time has been met.
            read_write_en <= '1';
            access_time_counter <= 1;
          end if;
        else
          access_time_counter <= 0;
        end if;
      end if;
    end if;
  end process;

end Behavioral;
