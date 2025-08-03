library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ISSI_IS61WV5128BLL_SRAM_Unit is
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
end ISSI_IS61WV5128BLL_SRAM_Unit;

architecture Behavioral of ISSI_IS61WV5128BLL_SRAM_Unit is
  constant ACCESS_TIMER_END : integer := (ACCESS_TIME_NS * IN_FREQ) / 1000000000;
  signal access_time_counter : integer := 0;
  signal access_time_counter_en : std_logic := '0';
  signal read_write_en : std_logic;
  signal write_data_reg : std_logic_vector(7 downto 0);
  signal sram_data_dir_out : std_logic := '0';
  signal sram_data_out : std_logic_vector(7 downto 0);
  signal sram_data_in : std_logic_vector(7 downto 0);

  type statetype is (IDLE, READ, WRITE, WRITE_DATA_VALID);
  signal state : statetype := IDLE;
begin
  sram_data <=  sram_data_out when sram_data_dir_out = '1' else (others => 'Z');
  sram_data_in  <= sram_data;

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
              write_data_reg <= data_in; -- data must be delayed due to t_HZWE
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
            -- TODO: Wait until going to IDLE
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
