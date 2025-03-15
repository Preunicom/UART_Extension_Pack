# UART Extension Pack (ExtPack)

## Features
The ExtPack is able to add units (like GPIO or UART) to a UART capable device.

## Communication with Host
The ExtPack communicates with the host over UART. <br>
The communication with the host has to be at least 8 data bits.
Stop bits and parity bit can be set as wished.

### Protocol with host
The ExtPack uses a custom protocol which uses UART as base. <br>
Each host to ExtPack data package consists of two UART packages following each other in less then three UART package cycles. <br>
The first one includes the unit number to communicate with (bits 5 downto 0) and the access mode for the unit (bits 7 downto 6). If there are more then 8 host UART data bits the following bits are ignored.<br>
The second one includes the data for the unit. If the unit uses less then your host UART data bits, the top bits are truncated in the unit wrapper (same the other way round if the unit has more bits than the host UART data bits). <br>
In the other direction from ExtPack to host the protocol is nearly the same with the difference of missing the access mode of the first UART package. These bits are always zero.

## Usage
### Declare and define units
Units are declared in the Main_Unit between "UNITS" and "UNITS END".
the first generic and the first 8 ports are the same for all units.
Following generics and ports are unit specific. <br>
The specific ports have to be additinally declared in the constraints file and in the entity of Main_Unit between "UNIT PORTS" and "UNIT PORTS END". 
(Note: The last line before "UNIT PORTS END" must not have a semicolon at the end!)

### Define host communication
Set the default values of Main_Unit to your specific UART configuration of your host. <br>
(Note: Make sure you have >= 8 data bits for your host communication as well as a BAUD rate less or equal of half your FPGA frequency)

## Internal structure
### Incoming data from host
(1) UART_Unit -> (2) Decoder -> (3) MUX -> (4) Unit
1) **UART_Unit** <br>
Receives the data via UART from rx_pin_host.
2) **Decoder** <br>
Decodes the received data in unit_number, access_mode and unit_data.
3) **MUX** <br>
Sends the enable signal to the unit with the decoded unit_number.
4) **Unit** <br>
Performs unit specific actions with the received data.

### Outgoing data to host
(1) Unit -> (2) PriorityScheduler -> (3) DEMUX -> (4) Encoder -> (5) UART_Unit
1) **Unit** <br>
Provides the data to send to the host.
2) **PriorityScheduler** <br>
Schedules the units with their priority (higher unit_number is less priority).
3) **DEMUX** <br>
Choose the unit_data chosen from PriorityScheduler and gives it to the Encoder.
4) **Encoder** <br>
Encodes the data in the protocoll.
5) **UART_Unit** <br>
Sends the data to the host over UART.