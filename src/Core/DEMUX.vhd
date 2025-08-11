--! @file
--! @brief Demultiplexer that routes input data to one of 64 outputs based on a control signal.
--! @details Uses a control vector to select which output enable line is asserted and sends the input data to all outputs.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--! Routes input data to the selected output channel based on the control vector.
entity DEMUX is
  Generic(
    DATA_BITS : integer := 8 --! The amount of data bits used by the ExtPack and the host.
  );
  Port ( 
    clk : in std_logic; --! Clock signal.
    rst : in std_logic; --! Reset signal.
    control : in STD_LOGIC_VECTOR(5 downto 0); --! 6-bit control signal selecting which output channel is active.
    inp_en : in STD_LOGIC; --! Input enable signal.
    inp_data : in std_logic_vector(DATA_BITS-1 downto 0); --! Input data bus.
    inp_acc_mode : in std_logic_vector(1 downto 0); --! Input access mode.
    outp_en : out STD_LOGIC_VECTOR(63 downto 0); --! 64-bit output enable vector, one bit per channel.
    outp_data : out std_logic_vector(DATA_BITS-1 downto 0); --! Output data bus.
    outp_acc_mode : out std_logic_vector(1 downto 0) --! Output access mode.
  );
end DEMUX;

--! Architecture implementing a clocked demultiplexer process.
architecture Behavioral of DEMUX is
begin
  --! Main demultiplexer process that updates outputs on the rising clock edge.
  MUX: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        outp_en <= (others => '0');
        outp_data <= (others => '0');
        outp_acc_mode <= (others => '0');
      else
        outp_en <= (others => '0');
        -- Set the selected output enable bit according to inp_en.
        outp_en(to_integer(unsigned(control))) <= inp_en;
        -- Delay signals to match enable signal timing.
        outp_data <= inp_data;
        outp_acc_mode <= inp_acc_mode;
      end if;
    end if;
  end process;
end Behavioral;
