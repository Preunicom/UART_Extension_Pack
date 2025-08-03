library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ISSI_IS61WV5128BLL_SRAM_Wrapper is
  Generic (
    HOST_DATA_BITS : integer := 8;
    IN_FREQ : integer := 12000000;
    ACCESS_TIME_NS : integer := 8
  );
  Port ( 
    clk, rst : in STD_LOGIC;
    write_en : in std_logic;
    access_mode : in std_logic_vector(1 downto 0); -- unused
    unit_data_in : in std_logic_vector(HOST_DATA_BITS-1 downto 0);
    unit_data_out : out std_logic_vector(13 downto 0) := (others => '0');
    scheduler_wanted : out std_logic;
    scheduler_done : in std_logic;
    error_to_host : out std_logic := '0';
    error_from_host : out std_logic := '0';
    sram_adr : out std_logic_vector(18 downto 0);
    sram_data : inout std_logic_vector(7 downto 0);
    sram_oen : out std_logic := '1';
    sram_cen : out std_logic := '1';
    sram_wen : out std_logic := '1'
  );
end ISSI_IS61WV5128BLL_SRAM_Wrapper;

architecture Behavioral of ISSI_IS61WV5128BLL_SRAM_Wrapper is
  component ISSI_IS61WV5128BLL_SRAM_Unit
    Generic (
      IN_FREQ : integer := 12000000;
      ACCESS_TIME_NS : integer := 8
    );
    Port ( 
      clk, rst : in STD_LOGIC;
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
  signal last_scheduler_done            : std_logic := '0';
  signal scheduling_active              : std_logic := '0';
  signal data_out_en                    : std_logic := '0';
  signal data_out                       : std_logic_vector(7 downto 0);
  signal sram_data_reg                  : std_logic_vector(7 downto 0);
  signal sram_adr_reg                   : unsigned(18 downto 0) := (others => '0');
  signal sram_adr_reg_next_slot_num     : unsigned(1 downto 0) := (others => '0');
  signal sram_error                     : std_logic;
  signal sram_adr_slot_access_error     : std_logic;
  signal read_en_unit                   : std_logic := '0';
  signal write_en_unit                  : std_logic := '0';
  constant SRAM_ADR_REG_SLOT_TWO_END    : integer := 2*HOST_DATA_BITS-1;
  constant SRAM_ADR_SLOT_TWO_IN_END     : integer := 18 - (HOST_DATA_BITS);
  constant SRAM_ADR_SLOT_THREE_IN_END   : integer := 18 - (2*HOST_DATA_BITS);
begin
  SRAM_COMP: ISSI_IS61WV5128BLL_SRAM_Unit generic map(IN_FREQ, ACCESS_TIME_NS) port map(clk, rst, read_en_unit, write_en_unit, sram_adr_reg, sram_data_reg, data_out, data_out_en, sram_adr, sram_data, sram_oen, sram_cen, sram_wen, sram_error);

  error_from_host <= sram_error or sram_adr_slot_access_error;

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
          -- scheduling finished --> resets request at scheduler
          scheduler_wanted <= '0';
          unit_data_out <= (others => '0');
          scheduling_active <= '0';
        end if;
        if data_out_en = '1' then
          if scheduling_active = '1' then
            -- Overwriting last timer interrupt -> Error
            error_to_host <= '1';
          end if;
          scheduler_wanted <= '1';
          unit_data_out(7 downto 0) <= data_out;
          scheduling_active <= '1';
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
        last_scheduler_done <= scheduler_done;
      end if;
    end if;
  end process;

end Behavioral;
