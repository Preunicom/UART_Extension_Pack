# UART Extension Pack (ExtPack)

## Features
The ExtPack is able to add units (like GPIO, Timer or UART) to a UART capable device like a microcontroller.

## Communication with Host
The ExtPack communicates with the host over UART.  
The communication data bits with the host has to be at least 8 data bits.
Stop bits and parity bit can be set as wished.

### Protocol with host
The ExtPack uses a custom protocol which uses UART as base.  
Each host to ExtPack data package consists of two UART packages following each other in less then three UART package cycles.  
The first one includes the unit number to communicate with (bits 5 downto 0) and the access mode for the unit (bits 7 downto 6). If there are more then 8 host UART data bits the following bits are ignored.  
The second one includes the data for the unit. If the unit uses less then your host UART data bits, the top bits are truncated in the unit wrapper (same the other way round if the unit has more bits than the host UART data bits).  
In the other direction from ExtPack to host the protocol is nearly the same with the difference of missing the access mode of the first UART package. These bits are always zero.

## Usage
### Declare and define units
Units are declared in the Main_Unit between "CUSTOM UNITS" and "UNITS END".
the first generic and the first 10 ports are the same for all units.
Following generics and ports are unit specific.  
The specific ports have to be additionally declared in the constraints file and in the entity of Main_Unit between "UNIT PORTS" and "UNIT PORTS END". 
**Note:** The last line before "UNIT PORTS END" must not have a semicolon at the end!  
Units with input pins have to use an IO_Sync. Every input pin has to declare an IO_Sync or IO_Sync_Vector between "UNIT SYNC" and "SYNC END".  
The corresponding signal has to be declared between "UNIT SYNC SIGNALS" and "SYNC SIGNALS END".  
Use the input pin signal declared in port(...) as "async_in" of IO_SYNC(_Vector) and the "sync_out" with the declared signal to the unit input.

### Define host communication
Set the default values of Main_Unit to your specific UART configuration of your host.  
**Note:** Make sure you have >= 8 data bits for your host communication as well as a BAUD rate less or equal of half your FPGA frequency

## Internal structure
### Incoming data from host
(1) UART_Unit -> (2) Decoder -> (3) MUX -> (4) Unit
1) **UART_Unit**  
Receives the data via UART from rx_pin_host.
2) **Decoder**  
Decodes the received data in unit_number, access_mode and unit_data.
3) **MUX**  
Sends the enable signal to the unit with the decoded unit_number.
4) **Unit**  
Performs unit specific actions with the received data.

### Outgoing data to host
(1) Unit -> (2) PriorityScheduler -> (3) DEMUX -> (4) Encoder -> (5) UART_Unit
1) **Unit**  
Provides the data to send to the host.
2) **PriorityScheduler**  
Schedules the units with their priority (higher unit_number is less priority).
3) **DEMUX**  
Choose the unit_data chosen from PriorityScheduler and gives it to the Encoder.
4) **Encoder**  
Encodes the data in the protocol.
5) **UART_Unit**  
Sends the data to the host over UART.