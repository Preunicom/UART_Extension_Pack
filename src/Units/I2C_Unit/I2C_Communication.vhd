--! @file
--! @brief I2C byte-level communication state machine.
--! @details Generates START/STOP/Repeated-START, sends the 7-bit address with R/W bit, handles ACK/NACK, transmits/receives one data byte, and reports idle and error status.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! Entity implementing the I2C byte transaction flow controlled by prescaled read/write enables.
entity I2C_Communication is
  port (
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    clk_en_read : in std_logic; --! Prescaled enable pulse for read sampling.
    clk_en_write : in std_logic; --! Prescaled enable pulse for write/update.
    SDA_in : in std_logic; --! Serial data input sampled from SDA line.
    SDA_out : out std_logic; --! Serial data output to SDA line ('0' drive, '1' release/open).
    write_en : in std_logic; --! Flag to start/continue a transaction.
    addr_data : in std_logic_vector(6 downto 0); --! 7-bit partner address.
    mode_recv : in std_logic; --! Mode select: '0' = write, '1' = read.
    send_data : in std_logic_vector(7 downto 0); --! Data byte to send in write mode.
    data_saved : out std_logic; --! Pulse: control/data accepted.
    recv_data : out std_logic_vector(7 downto 0); --! Received data byte.
    recv_data_valid : out std_logic; --! Pulse: recv_data is valid.
    is_idle : out std_logic; --! High when FSM is idle.
    error : out std_logic --! Error flag (e.g., NACK received).
  );
end I2C_Communication;

--! Architecture implementing the I2C byte-transaction finite state machine (FSM).
architecture Behavioral of I2C_Communication is
  --! @brief FSM states covering START, address bits, ACK cycles, data send/receive, repeated START, STOP, and error handling.
  --! @details S=Send, R=Receive, A=Address, B=Bit, ACK_Z=ACK_Z_state, ACK_R=ACK_Read 
  type communication_state_type is (IDLE, START, PREP_REP_START, REP_START,
                                    SA0, SA1, SA2, SA3, SA4, SA5, SA6, SRW, AACK_Z, AACK_R,
                                    SB0, SB1, SB2, SB3, SB4, SB5, SB6, SB7, SACK, SACK_DELAY,
                                    RB0, RB1, RB2, RB3, RB4, RB5, RB6, RB7, RACK_Z, RACK_R,
                                    STOP_PREP, STOP, ERR
                                    );
  --! Current state of the I2C communication FSM.
  signal communication_state : communication_state_type := IDLE;

  --! Control register holding {addr[6:0], R/W} for transmission.
  signal ctrl_reg : std_logic_vector(7 downto 0);
  --! Register holding the data byte to transmit in write mode.
  signal send_reg : std_logic_vector(7 downto 0);
  --! Register capturing the received data byte in read mode.
  signal recv_reg : std_logic_vector(7 downto 0);

begin

  --! Main FSM process: sequences START/ADDR/ACK, send/receive byte, optional repeated START, and STOP; sets SDA_out and status flags.
  MANAGE: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ctrl_reg <= (others=>'1');
        send_reg <= (others=>'1');
        recv_reg <= (others=>'1');
        communication_state <= IDLE;
        SDA_out <= '1';
        data_saved <= '0';
        error <= '0';
        recv_data_valid <= '0';
        recv_data <= (others => '1');
        is_idle <= '1';
      else
        -- Read or Write edge in SCL
        data_saved <= '0';
        error <= '0';
        recv_data_valid <= '0';
        is_idle <= '0';
        case communication_state is
          when IDLE => 
            -- Wait for write_en
            is_idle <= '1';
            if write_en = '1' then
              -- Save data to send
              ctrl_reg <= addr_data & mode_recv;
              send_reg <= send_data;
              data_saved <= '1';
              communication_state <= START;
            end if;
          when START =>
            -- Wait for the signal to be HIGH
            is_idle <= '1';
            if clk_en_read = '1' then
              -- Rising edge --> Send START signal
              SDA_out <= '0';
              communication_state <= SA0;
            end if;
          when SA0 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(7);
              communication_state <= SA1;
            end if;
          when SA1 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(6);
              communication_state <= SA2;
            end if;
          when SA2 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(5);
              communication_state <= SA3;
            end if;
          when SA3 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(4);
              communication_state <= SA4;
            end if;
          when SA4 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(3);
              communication_state <= SA5;
            end if;
          when SA5 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(2);
              communication_state <= SA6;
            end if;
          when SA6 => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(1);
              communication_state <= SRW;
            end if;
          when SRW => 
            if clk_en_write = '1' then
              SDA_out <= ctrl_reg(0);
              communication_state <= AACK_Z;
            end if;
          when AACK_Z => 
            -- Prepare for receiving ACK
            if clk_en_write = '1' then
              SDA_out <= '1';
              communication_state <= AACK_R;
            end if;
          when AACK_R => 
            -- Read ACK
            if clk_en_read = '1' then
              if SDA_in = '0' then
                -- ACK
                if ctrl_reg(0) = '0' then
                  -- Send
                  communication_state <= SB0;
                else
                  -- Receive
                  communication_state <= RB0;
                end if;
              else 
                -- NACK
                communication_state <= ERR;
              end if;
            end if;
          when SB0 => 
            -- Send Bit
            if clk_en_write = '1' then
              SDA_out <= send_reg(7);
              communication_state <= SB1;
            end if;
          when SB1 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(6);
              communication_state <= SB2;
            end if;
          when SB2 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(5);
              communication_state <= SB3;
            end if;
          when SB3 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(4);
              communication_state <= SB4;
            end if;
          when SB4 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(3);
              communication_state <= SB5;
            end if;
          when SB5 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(2);
              communication_state <= SB6;
            end if;
          when SB6 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(1);
              communication_state <= SB7;
            end if;
          when SB7 => 
            if clk_en_write = '1' then
              SDA_out <= send_reg(0);
              communication_state <= RACK_Z;
            end if;
          when RACK_Z => 
            -- Prepare for receiving ACK
            if clk_en_write = '1' then
              SDA_out <= '1';
              communication_state <= RACK_R;
            end if;
          when RACK_R => 
            -- Read ACK
            if clk_en_read = '1' then
              if SDA_in = '0' then
                -- ACK
                if write_en = '1' then
                  -- Send/Recv next
                  -- Save data to send
                  if (mode_recv = '0') and (ctrl_reg(7 downto 1) = addr_data) then
                    -- Send next
                    send_reg <= send_data;
                    data_saved <= '1';
                    communication_state <= SB0;
                  else
                    -- Receive next or new addr --> Repeated Start
                    ctrl_reg <= addr_data & mode_recv;
                    send_reg <= send_data;
                    data_saved <= '1';
                    communication_state <= PREP_REP_START; -- ACK --> SDA LOW --> PREP needed
                  end if;
                else 
                  -- Stop 
                  communication_state <= STOP_PREP;
                end if;
              else
                -- NACK
                communication_state <= ERR;
              end if;
            end if;
          when RB0 => 
            -- Receive Bit
            if clk_en_read = '1' then
              recv_reg(7) <= SDA_in;
              communication_state <= RB1;
            end if;
          when RB1 => 
            if clk_en_read = '1' then
              recv_reg(6) <= SDA_in;
              communication_state <= RB2;
            end if;
          when RB2 => 
            if clk_en_read = '1' then
              recv_reg(5) <= SDA_in;
              communication_state <= RB3;
            end if;
          when RB3 => 
            if clk_en_read = '1' then
              recv_reg(4) <= SDA_in;
              communication_state <= RB4;
            end if;
          when RB4 =>
            if clk_en_read = '1' then
              recv_reg(3) <= SDA_in;
              communication_state <= RB5;
            end if;
          when RB5 => 
            if clk_en_read = '1' then
              recv_reg(2) <= SDA_in;
              communication_state <= RB6;
            end if;
          when RB6 => 
            if clk_en_read = '1' then
              recv_reg(1) <= SDA_in;
              communication_state <= RB7;
            end if;
          when RB7 => 
            if clk_en_read = '1' then
              recv_reg(0) <= SDA_in;
              communication_state <= SACK;
            end if;
          when SACK => 
            recv_data <= recv_reg;
            recv_data_valid <= '1';
            SDA_out <= '1'; -- NACK to stop reading
            if clk_en_write = '1' then
              if write_en = '1' then
                -- Send/Recv next
                -- Save data to send
                if (mode_recv = '1') and (ctrl_reg(7 downto 1) = addr_data) then
                  -- Receive next
                  SDA_out <= '0'; -- ACK to continue reading
                  data_saved <= '1';
                  communication_state <= SACK_DELAY;
                else
                  -- Send next or new addr --> Repeated Start
                  ctrl_reg <= addr_data & mode_recv;
                  send_reg <= send_data;
                  data_saved <= '1';
                  communication_state <= PREP_REP_START;
                end if;
              else 
                -- Stop 
                communication_state <= STOP_PREP;
              end if;
            end if;
          when SACK_DELAY =>
            -- wait for the ACK of the receivced byte to be sent before reading the next data
            if clk_en_write = '1' then
              SDA_out <= '1';
              communication_state <= RB0;
            end if;
          when ERR => 
            error <= '1';
            communication_state <= STOP_PREP;
          when PREP_REP_START =>
            -- Prepare REPEATED START signal by setting SDA to HIGH
            if clk_en_write = '1' then
              SDA_out <= '1';
              communication_state <= REP_START;
            end if;
          when REP_START =>
            -- Wait for the signal to be HIGH
            if clk_en_read = '1' then
              -- SCL HIGH --> Send START signal
              SDA_out <= '0';
              communication_state <= SA0;
            end if;
          when STOP_PREP => 
            -- Wait for the signal to be LOW
            if clk_en_write = '1' then
              -- Prepare SDA to be low for the STOP signal
              SDA_out <= '0';
              communication_state <= STOP;
            end if;
          when STOP => 
            -- Wait for the signal to be HIGH
            if clk_en_read = '1' then
              -- SCL HIGH --> Send STOP signal
              SDA_out <= '1';
              communication_state <= IDLE;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

end Behavioral;