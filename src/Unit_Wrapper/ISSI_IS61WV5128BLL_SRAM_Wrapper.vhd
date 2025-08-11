--! @file
--! @brief Wrapper for ISSI_IS61WV5128BLL_SRAM_Unit with scheduler/host interface.
--! @details Builds SRAM addresses from host chunks, triggers read/write on the SRAM unit, and schedules read data back to the host. Reports address-slot and SRAM protocol errors.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! \defgroup UNIT_WRAPPER ExtPack unit wrapper.
--! @brief Wrapper for units of ExtPack.
--! @{

--! @brief Wraps the ISSI_IS61WV5128BLL_SRAM_Unit and exposes a simple command interface to the host via the scheduler.
--! @details The ISSI_IS61WV5128BLL_SRAM_Unit (short: SRAM_Unit) is used to communicate with the internal SRAM Module (of the Cmod A7 35T).\n
--! It can be configured with the time needed to access data in ns (8/10/20/25/35) (Use the datasheet to identify the correct one; The Cmod A7 35T needs the 8ns configuration)
--! @note As the part uses the same clock as the FPGA the pins does not have to be synced.
--! @details The SRAM_Unit needs following pins:\n
--! - sram_adr (out (vector: 19x))\n
--! - sram_data (inout (vector: 8x))\n
--! - sram_oen (out)\n
--! - sram_cen (out)\n
--! - sram_wen (out)
--! @details The access mode handles writing, reading and setting address:\n
--! - "00": Reseting the address to 0x0000 and setting the next address slot to write to 0\n
--! - "01": Setting the next address slot to the data\n
--! - "10": Reading the data from the set address\n
--! - "11": Writing the data to the set address
--! @details There are three situations where errors are forwarded to the Error_Unit:\n
--! - Too slow scheduling (error_to_host)\n
--! - Reading or writing while another read/write operation is still processed (error_from_host)\n
--! - Writing in an address slot above the address length (error_from_host)
--! @details The address is set in blocks of HOST_DATA_BITS. The last block may not be used completely (bits above the used ones are ignored).
--! The first block sets the LSB. The second one the next, etc.
--! When a block is set completely above the address (no bit is still unset in the address) there will be an error_from_host and the received data will we ignored.
--! To start again, reset the address to zero (access_mode: "00").
--! @note If there was a read or write operation the next address block to set is reset to the first block but the address is still valid and not reset to zero.\n
--! This allows the host to modify for example the last bit of the address without setting all blocks again.
entity ISSI_IS61WV5128BLL_SRAM_Wrapper is
--! @}
  Generic (
    HOST_DATA_BITS : integer := 8; --! Width of the host data bus in bits.
    IN_FREQ : integer := 12000000; --! Input clock frequency in Hz.
    ACCESS_TIME_NS : integer := 8 --! SRAM access time in nanoseconds for the underlying unit. (See the datasheet for the exact value)
  );
  Port ( 
    clk : in STD_LOGIC; --! Clock signal.
    rst : in STD_LOGIC; --! Reset signal.
    write_en : in std_logic; --! Host write strobe.
    access_mode : in std_logic_vector(1 downto 0); --! Command: "00" reset address, "01" push address bits, "10" read, "11" write.
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0); --! Payload from host (addr/data chunk).
    unit_data_out : out std_logic_vector(13 downto 0) := (others => '0'); --! Data to host (read data, zero-extended).
    scheduler_wanted : out std_logic; --! Request to scheduler for sending unit_data_out.
    scheduler_done : in std_logic; --! Scheduler acknowledge of completed send.
    error_to_host : out std_logic := '0'; --! Error: read data overwrite while previous response pending.
    error_from_host : out std_logic := '0'; --! Error: SRAM unit error or invalid address slot access.
    sram_adr : out std_logic_vector(18 downto 0); --! Physical SRAM address bus.
    sram_data : inout std_logic_vector(7 downto 0); --! Physical SRAM data bus.
    sram_oen : out std_logic := '1'; --! SRAM OE# (active low).
    sram_cen : out std_logic := '1'; --! SRAM CE# (active low).
    sram_wen : out std_logic := '1' --! SRAM WE# (active low).
  );
end ISSI_IS61WV5128BLL_SRAM_Wrapper;

--! Architecture connecting the host command protocol to the SRAM unit and the scheduler.
architecture Behavioral of ISSI_IS61WV5128BLL_SRAM_Wrapper is
  --! Component declaration for the SRAM unit.
  component ISSI_IS61WV5128BLL_SRAM_Unit
    Generic (
      IN_FREQ : integer := 12000000;
      ACCESS_TIME_NS : integer := 8
    );
    Port ( 
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      read_en : in std_logic;
      write_en : in std_logic;
      adr_in : in unsigned(18 downto 0);
      data_in : in std_logic_vector(7 downto 0);
      data_out : out std_logic_vector(7 downto 0);
      data_out_en : out std_logic;
      sram_adr : out std_logic_vector(18 downto 0);
      sram_data : inout std_logic_vector(7 downto 0);
      sram_oen : out std_logic := '1';
      sram_cen : out std_logic := '1';
      sram_wen : out std_logic := '1';
      error : out std_logic := '0'
    );
  end component;
  --! Previous value of scheduler_done for edge detection.
  signal last_scheduler_done            : std_logic := '0';
  --! Indicates a response is pending until scheduler_done.
  signal scheduling_active              : std_logic := '0';
  --! Strobe from SRAM unit indicating read data is valid.
  signal data_out_en                    : std_logic := '0';
  --! Data byte read from SRAM unit.
  signal data_out                       : std_logic_vector(7 downto 0);
  --! Latched write data byte for SRAM writes.
  signal sram_data_reg                  : std_logic_vector(7 downto 0);
  --! Assembled SRAM address register.
  signal sram_adr_reg                   : unsigned(18 downto 0) := (others => '0');
  --! Next address slot index (0..3) to be filled from host chunks.
  signal sram_adr_reg_next_slot_num     : unsigned(1 downto 0) := (others => '0');
  --! Error flag from SRAM unit (protocol/timing violation).
  signal sram_error                     : std_logic;
  --! Error when host attempts to fill a non-existent address slot.
  signal sram_adr_slot_access_error     : std_logic;
  --! Read enable forwarded to SRAM unit.
  signal read_en_unit                   : std_logic := '0';
  --! Write enable forwarded to SRAM unit.
  signal write_en_unit                  : std_logic := '0';
  --! Upper bit index of address slot 2 within the address register.
  constant SRAM_ADR_REG_SLOT_TWO_END    : integer := 2*HOST_DATA_BITS-1;
  --! Upper bit index taken from host data for slot 2 (when clipping to 19 bits).
  constant SRAM_ADR_SLOT_TWO_IN_END     : integer := 18 - (HOST_DATA_BITS);
  --! Upper bit index taken from host data for slot 3 (when clipping to 19 bits).
  constant SRAM_ADR_SLOT_THREE_IN_END   : integer := 18 - (2*HOST_DATA_BITS);
begin
  --! The SRAM Unit handling the communication with the SRAM hardware.
  SRAM_COMP: ISSI_IS61WV5128BLL_SRAM_Unit generic map(IN_FREQ, ACCESS_TIME_NS) port map(clk, rst, read_en_unit, write_en_unit, sram_adr_reg, sram_data_reg, data_out, data_out_en, sram_adr, sram_data, sram_oen, sram_cen, sram_wen, sram_error);

  error_from_host <= sram_error or sram_adr_slot_access_error;

  --! Host command handling: builds address, issues read/write to SRAM unit.
  CONTROL_REQUEST: process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sram_adr_slot_access_error <= '0';
        read_en_unit <= '0';
        write_en_unit <= '0';
        sram_adr_reg_next_slot_num <= (others => '0');
        sram_adr_reg <= (others => '0');
        sram_data_reg <= (others => '0');
      else
        sram_adr_slot_access_error <= '0';
        read_en_unit <= '0';
        write_en_unit <= '0';
        if write_en = '1' then
          -- Received data from host
          case access_mode is
            when "00" =>
              -- Reset address
              sram_adr_reg_next_slot_num <= (others => '0');
              sram_adr_reg <= (others => '0');
            when "01" =>
              -- Add address bits to the front
              case sram_adr_reg_next_slot_num is
                when "00" => 
                  -- Slot 1
                  sram_adr_reg(HOST_DATA_BITS-1 downto 0) <= unsigned(unit_data_in);
                  sram_adr_reg_next_slot_num <= sram_adr_reg_next_slot_num + 1;
                when "01" =>
                  --  Slot 2
                  if(SRAM_ADR_REG_SLOT_TWO_END > 18) then
                    sram_adr_reg(18 downto HOST_DATA_BITS) <= unsigned(unit_data_in(SRAM_ADR_SLOT_TWO_IN_END downto 0));
                  else
                    sram_adr_reg(SRAM_ADR_REG_SLOT_TWO_END downto HOST_DATA_BITS) <= unsigned(unit_data_in);
                  end if;
                  sram_adr_reg_next_slot_num <= sram_adr_reg_next_slot_num + 1;
                when "10" =>
                  -- Slot 3
                  sram_adr_reg(18 downto SRAM_ADR_REG_SLOT_TWO_END+1) <= unsigned(unit_data_in(SRAM_ADR_SLOT_THREE_IN_END downto 0));
                  sram_adr_reg_next_slot_num <= sram_adr_reg_next_slot_num + 1;
                when "11" => 
                  -- Slot 4 (can never be reached as HOST_DATA_BITS >= 8)
                  sram_adr_slot_access_error <= '1';
                when others => null;
              end case;
            when "10" =>
              -- Read data
              read_en_unit <= '1';
              sram_adr_reg_next_slot_num <= (others => '0');
            when "11" =>
              -- Write data
              write_en_unit <= '1';
              sram_data_reg <= unit_data_in(7 downto 0);
              sram_adr_reg_next_slot_num <= (others => '0');
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process;

  --! Response scheduler: forwards read data to host and handles overwrite detection.
  RESPONSE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        scheduler_wanted <= '0';
        unit_data_out <= (others => '0');
        scheduling_active <= '0';
        error_to_host <= '0';
      else
        error_to_host <= '0';
        if last_scheduler_done = '0' and scheduler_done = '1' then
          -- Scheduling finished: clear scheduler request and data.
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        end if;
        if data_out_en = '1' then
          if scheduling_active = '1' then
            -- Overwriting pending read response: raise error.
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out(7 downto 0) <= data_out;
          scheduling_active <= '1';
        end if;
      end if;
    end if;
  end process;

  --! Edge detection: captures previous scheduler_done.
  EDGE_DETECTION: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        last_scheduler_done <= '0';
      else
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;
