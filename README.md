# UART Extension Pack (ExtPack)

## Features
The ExtPack is able to communicate with an UART capable device like a microcontroller (named host in the following) and can extend its periphery.
There are units (like GPIO, Timer or UART) which can be controlled by the host.
There are up to 64 units (Three of them are not customizable as they are units used to provide basic important features for the communication like resets, errors and acknowledges).

## Communication with Host
The ExtPack communicates with the host over UART.  
The communication data bits with the host has to be at least 8 data bits.
Stop bits and parity bit can be set as wished.
In sum there can be a maximum of 15 bits per UART package.

### Protocol with host
The ExtPack uses a custom protocol which uses UART as base.  
Each host to ExtPack data package consists of two UART packages following each other in less then three UART package cycles.  
The first one includes the unit number to communicate with (bits 0...5) and the access mode for the unit (bits 6...7). If there are more than 8 host UART data bits the following bits are ignored.  
The second one includes the data for the unit. If the unit uses less then your host UART data bits, the top bits are truncated in the unit wrapper (same the other way round if the unit works with more bits than the host UART data bits the data is filled with zeros).  
In the other direction from ExtPack to host the protocol is nearly the same with the difference of missing the access mode of the first UART package. These bits have to be always zero.

## Usage
### Declare and define units
Use the ExtPack_Management component.  
Then use the units you like as components.  
Connect the ExtPack_Management with the units. The index in vectors need to match the unit number you want to set for the unit. (The available unit numbers are 3...63)  
All units are using the same first generic and the same first 10 ports.  
Following generics and ports are unit specific.  
Units with input pins have to be synced. This can be done by using the IO_Sync or IO_Sync_Vector component.

### Define host communication
Set the generic values of the ExtPack_Management component to your specific UART configuration of your host.  
**Note:** Make sure to match all port conditions in the Doxygen documentation.

## Internal structure
### Incoming data from host
(1) UART_Unit -> (2) Decoder -> (3) MUX -> (4) Unit
1) **UART_Unit**  
Receives the data via UART from the RX pin.
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
Schedules the units with their priority (higher unit number is less priority).
3) **DEMUX**  
Choose the unit data chosen from PriorityScheduler and gives it to the Encoder.
4) **Encoder**  
Encodes the data in the protocol.
5) **UART_Unit**  
Sends the data to the host via UART over the TX pin.

## VHDL
The used VHDL version is VHDL 2K.