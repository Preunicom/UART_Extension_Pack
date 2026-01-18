--! @file
--! @brief I2C wrapper integrating I2C_Unit with host/scheduler interface.
--! @details Allows the host to set partner addresses, send and receive data over I2C. Manages readiness, scheduler handshakes, and error reporting.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

--! \defgroup UNIT_WRAPPER ExtPack unit wrapper.
--! @brief Wrapper for units of ExtPack.
--! @{

--! @brief Wraps an I2C_Unit to handle host commands and interface with the scheduler.
--! @details I2C uses MSB.  
--! It uses repeated start when sending packages directly following on each other to different slaves or to the same slave with another mode (send/receive).  
--! Packages to the same slave with the same mode (send/receive) following on each other are directly sent after the ACK.  
--! The internal buffer helps to have longer transactions by storing data while waiting for the previous items in the transaction to be processed.  
--! The Unit supports slave clock stretching of slaves.  
--! @note 
--! - The I2C Unit does not work with multiple masters. It has to be the only master on the bus.\n
--! - This unit can not be synced as the pin is inout!
--! @details The I2C_Unit needs following pins:\n
--! - SCL (inout) (The pin/connection has to be connected with a pull-up resistor)\n
--! - SDA (inout) (The pin/connection has to be connected with a pull-up resistor)
--! @details The access mode handles data sending and the current slave ID:\n
--! - "*1": Sets partner address (lowest 7 bits of received data)\n
--! - "10": Receives a message from the partner with currently set partner address\n
--! - "00": Sends a message to the partner with currently set partner address
--! @details There are three situations where errors are forwarded to the Error_Unit:\n
--! - Too slow scheduling (error_to_host)\n
--! - Sending command while another command is already waiting for the I2C Unit to be ready (error_from_host)\n
--! - NACK received while sending (error_from_host)
entity I2C_Wrapper is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host UART data in bits.
    IN_FREQ_HZ : integer := 12000000; --! Input clock frequency in Hz (must be at least 4x I2C_FREQ_HZ).
    I2C_FREQ_HZ : integer := 100000; --! I2C bus frequency in Hz.
    I2C_BUF_LEN : integer := 10 --! I2C buffer length in data bytes.
  );
  Port (
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Enable signal for the input signals.
    access_mode : in std_logic_vector(1 downto 0); --! Access mode: 01/11=sets partner address, otherwise sends/receives.
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Data from host (address or payload).
    unit_data_out : out std_logic_vector(13 downto 0); --! Data to host (received from I2C partner).
    scheduler_wanted : out std_logic; --! Request to scheduler for sending unit_data_out.
    scheduler_done : in std_logic; --! Scheduler acknowledge for completed send.
    error_to_host : out std_logic := '0'; --! Error flag: data overwrite in receive buffer.
    error_from_host : out std_logic := '0'; --! Error flag: I2C not ready or not expected NACK.
    SCL : inout std_logic; --! I2C clock line.
    SDA : inout std_logic --! I2C data line.
  );
end I2C_Wrapper;

--! Architecture connecting I2C_Unit to the scheduler, handling host commands, and managing errors.
architecture Behavioral of I2C_Wrapper is
  --! Component declaration for I2C_Unit: handles low-level I2C operations.
  component I2C_Unit
    generic(
      IN_FREQ_HZ  : integer := 12000000;
      I2C_FREQ_HZ : integer := 100000
    );
    port(
      clk : in std_logic;
      rst : in std_logic;
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

  --! Previous write_en for edge detection.
  signal last_write_enable : std_logic := '0';
  --! Previous scheduler_done for edge detection.
  signal last_scheduler_done : std_logic := '0';
  --! Indicates that a receive transaction is active.
  signal scheduling_active : std_logic := '0';

  --! Buffer for received data, zero-extended to 14 bits.
  signal unit_data_out_buffer : std_logic_vector(13 downto 0) := (others => '0');
  --! @brief Subdata type for I2C buffered payload data.
  --! @details Array of std_logic_vector used to store the payload data for each buffered I2C transaction.
  type i2c_buf_data_t is array (I2C_BUF_LEN-1 downto 0) of std_logic_vector(13 downto 0); 
  --! Buffer for data to send, zero-extended to 14 bits.
  signal i2c_buf_data : i2c_buf_data_t := (others => (others => '0'));

  --! @brief Subdata type for I2C partner addresses.
  --! @details Array of 7-bit std_logic_vector to store the target addresses for each buffered I2C transaction.
  type i2c_buf_addr_t is array (I2C_BUF_LEN-1 downto 0) of std_logic_vector(6 downto 0); 
  --! Buffer for the address of the data to send in the data buffer.
  signal i2c_buf_addr: i2c_buf_addr_t := (others => (others => '0'));

  --! @brief Subdata type for I2C receive mode flags.
  --! @details Array of single-bit flags, where '1' indicates the transaction is a receive operation and '0' indicates a send operation. One element per buffered transaction.
  type i2c_buf_recv_mode_t is array (I2C_BUF_LEN-1 downto 0) of std_logic; 
  --! Buffer of mode flags: '1' for receive, '0' for send.
  signal i2c_buf_recv_mode: i2c_buf_recv_mode_t := (others => '0');

  --! The amount of free slots in the buffer.
  signal free_i2c_buf_slots : natural range 0 to I2C_BUF_LEN := I2C_BUF_LEN;

  --! Flag to start I2C_Unit transaction. Is '1' if any valid data is in the buffer, '0' otherwise.
  signal i2c_write_en : std_logic := '0';
  --! Current 7-bit partner address.
  signal current_partner_adr : std_logic_vector(6 downto 0) := (others => '0');

  --! Previous I2C_data_saved for edge detection.
  signal last_I2C_data_saved : std_logic;
  --! I2C_Unit output: data saved indicator.
  signal I2C_data_saved : std_logic;

  --! Previous recv_data_valid for edge detection.
  signal last_recv_data_valid : std_logic;
  --! I2C_Unit output: receive data valid indicator.
  signal recv_data_valid : std_logic;

  --! Error: I2C transaction attempted while no free space in buffer.
  signal error_I2C_buffer_full : std_logic := '0';
  --! Error: I2C partner did not acknowledge.
  signal error_I2C_NACK : std_logic := '0';

begin
  --! The I2C Unit handling the I2C communication.
  I2C: I2C_Unit generic map(IN_FREQ_HZ, I2C_FREQ_HZ) port map(clk, rst, i2c_write_en, i2c_buf_addr(0), i2c_buf_recv_mode(0), i2c_buf_data(0)(7 downto 0), I2C_data_saved, unit_data_out_buffer(7 downto 0), recv_data_valid, error_I2C_NACK, SCL, SDA);

  --! Handles host write_en edges, sets partner address, and starts I2C transactions if ready by using a buffer.
  I2C_COMM: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        error_I2C_buffer_full <= '0';
        current_partner_adr <= (others => '0');
        i2c_buf_addr <= (others => (others => '0'));
        i2c_buf_recv_mode <= (others => '0');
        i2c_buf_data <= (others => (others => '0'));
        free_i2c_buf_slots <= I2C_BUF_LEN;
        i2c_write_en <= '0';
      else
        error_I2C_buffer_full <= '0';
        if last_I2C_data_saved = '0' and I2C_data_saved = '1' then
          -- Shift the data in the buffer one idx to the front if valid data exists
          free_i2c_buf_slots <= free_i2c_buf_slots + 1;
          if free_i2c_buf_slots < I2C_BUF_LEN - 1 then
            -- Buffer not empty after the processed item is poped.
            for i in 0 to I2C_BUF_LEN-2 loop
              i2c_buf_addr(i) <= i2c_buf_addr(i+1);
              i2c_buf_recv_mode(i) <= i2c_buf_recv_mode(i+1);
              i2c_buf_data(i) <= i2c_buf_data(i+1);
            end loop;
          else
            -- No data in buffer remaining
            i2c_write_en <= '0';
          end if;
        end if;
        if last_write_enable = '0' and write_en = '1' then
          -- Rising edge of write_en detected.
          if access_mode(0) = '1' then
            -- Set current partner address (access mode bit0=1).
            current_partner_adr <= unit_data_in(6 downto 0);
          else
            if free_i2c_buf_slots > 0 then
              -- Free buffer slot --> Take this slot
              free_i2c_buf_slots <= free_i2c_buf_slots - 1;
              i2c_write_en <= '1';
              i2c_buf_addr(I2C_BUF_LEN - free_i2c_buf_slots) <= current_partner_adr;
              if access_mode(1) = '1' then
                -- Receive data (access mode bit1=1).
                i2c_buf_recv_mode(I2C_BUF_LEN - free_i2c_buf_slots) <= '1';
              else
                -- Send data (access mode bit1=0).
                i2c_buf_recv_mode(I2C_BUF_LEN - free_i2c_buf_slots) <= '0';
              end if;
              i2c_buf_data(I2C_BUF_LEN - free_i2c_buf_slots)(HOST_DATA_BITS-1 downto 0) <= unit_data_in;
            else
              -- Error: No free buffer slot.
              error_I2C_buffer_full <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  --! Handles incoming I2C data, schedules it for host send, and detects overwrite errors.
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
          -- Scheduling finished: clear request and data.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        elsif last_recv_data_valid = '0' and recv_data_valid = '1' then
          -- Rising edge of recv_data_valid: new I2C data available.
          if scheduling_active = '1' then
            -- Overwriting pending I2C data: raise error.
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out <= unit_data_out_buffer;
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;

  --! Combines I2C not ready and NACK errors into error_from_host.
  ERR: process(clk)
	begin
    if rising_edge(clk) then
      if rst = '1' then
        error_from_host <= '0';
      else
        error_from_host <= error_I2C_buffer_full or error_I2C_NACK;
      end if;
    end if;
  end process;

  --! Captures previous values of handshake and status signals for edge detection.
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