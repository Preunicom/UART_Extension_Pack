--! @file
--! @brief Top-level I2C unit.
--! @details Coordinates I2C prescaling and byte-level communication, exposing a simple read/write interface and open-drain SCL/SDA control.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

--! \defgroup UNIT ExtPack units
--! @brief Standard units of ExtPack.
--! @{

--! @brief Entity implementing an I2C master with prescaler and communication state machine submodules.
--! @details I2C unit with maximum quarter of FPGA Frequency and 8 Bit data. Transactions are automatically used with a repeated start signal.
entity I2C_Unit is
--! @}
  generic(
    IN_FREQ_HZ  : integer := 12000000; --! Input clock frequency in Hz. @note Condition: IN_FREQ_HZ >= 4x I2C_FREQ_HZ.
    I2C_FREQ_HZ : integer := 100000 --! Target I2C bus frequency in Hz.
  );
  port(
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    write_en : in std_logic; --! Strobe to start a transaction (read or write).
    adr : in std_logic_vector(6 downto 0); --! 7-bit partner address.
    mode_recv : in std_logic; --! Mode: '0' = write, '1' = read.
    send_data : in std_logic_vector(7 downto 0); --! Byte to send on write.
    data_saved : out std_logic; --! Pulse: command/data accepted.
    recv_data : out std_logic_vector(7 downto 0); --! Byte received from I2C partner.
    recv_data_valid : out std_logic; --! Pulse: `recv_data` is valid.
    error : out std_logic; --! Error flag (e.g., NACK/timeout).
    SCL : inout std_logic; --! I2C clock line (open-drain).
    SDA : inout std_logic --! I2C data line (open-drain).
  );
end I2C_Unit;

--! Architecture wiring the communication core and the prescaler; handles SCL/SDA open-drain behavior.
architecture Behavioral of I2C_Unit is
  --! Component declaration for I2C_Communication (byte-level I2C state machine).
  component I2C_Communication
    port (
      clk, rst, clk_en_read, clk_en_write : in std_logic;
      SDA_in : in std_logic;
      SDA_out : out std_logic;
      write_en : in std_logic;
      addr_data : in std_logic_vector(6 downto 0);
      mode_recv : in std_logic;
      send_data : in std_logic_vector(7 downto 0);
      data_saved : out std_logic;
      recv_data : out std_logic_vector(7 downto 0);
      recv_data_valid : out std_logic;
      is_idle : out std_logic;
      error : out std_logic
    );
  end component;
  --! Component declaration for I2C_Prescaler (generates read/write enables and SCL).
  component I2C_Prescaler
    generic (
      IN_FREQ_HZ  : integer := 12000000;
      OUT_FREQ_HZ : integer := 100000
    );
    port (
      clk, rst : in  STD_LOGIC;
      clk_en_read : out std_logic;
      clk_en_write : out std_logic;
      SCL_in : in std_logic;
      SCL_out : out std_logic
    );
  end component;

  --! Prescaled enable for read phase timing.
  signal clk_en_read : std_logic;
  --! Prescaled enable for write phase timing.
  signal clk_en_write : std_logic;
  --! Indicates I2C bus idle; releases SCL when '1'.
  signal SCL_en : std_logic;
  --! Internal SDA input/output (open-drain control).
  signal SDA_in, SDA_out : std_logic;
  --! Internal SCL input/output (open-drain control).
  signal SCL_in, SCL_out : std_logic;

begin

  --! Instantiate I2C communication core.
  COMM: I2C_Communication port map(clk, rst, clk_en_read, clk_en_write, SDA_in, SDA_out, write_en, adr, mode_recv, send_data, data_saved, recv_data, recv_data_valid, SCL_en, error);
  --! Instantiate I2C prescaler.
  PRES: I2C_Prescaler generic map(IN_FREQ_HZ, I2C_FREQ_HZ) port map(clk, rst, clk_en_read, clk_en_write, SCL_in, SCL_out);
  
  SDA     <= '0' when SDA_out = '0' else 'Z';
  SDA_in  <= SDA;

  SCL     <= '0' when ((SCL_out = '0') and (not (SCL_en = '1'))) else 'Z';
  SCL_in  <= SCL;

end Behavioral;