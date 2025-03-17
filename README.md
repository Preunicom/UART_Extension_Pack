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

## Units
### UART_Unit
Can be configured with BAUD rate, data bits, stop bits and parity bit. <br>
Needs two pins (rx and tx) of the FPGA. <br>
BAUD has to be less or equal than half of the FGGA frequency. (Note: Integer divisor baud rates lead to more stable UART communication) <br>
Data bits have to be more than 5 and all bits (stop, data and parity) have to be less or equal 15. <br>
Normally: 
  - data bits: 5-9
  - stop bits: 1-2
  - parity bit: 0-1

UART messages are directly forwarded from unit to the host or from the host to the unit. <br>
Access mode is ignored. <br>
Note: UART messages with parity or frame errors are ignorer! <br>
Note: If there is too much traffic on the ExtPack and UART Unit has to less priority and is receiving too much laod it is posible that UART packages are getting lost because it is scheduled too slow or never because of starvation.

### GPIO_Unit
Can be configured with in and out pin amount. <br>
Pin amount has to be at least 1 and maximum the amount of data bits of the host UART communication.
The access mode controls the type of pins.
  - "00" or "10": Set output pins
  - "01" or "11": Request values of input pins

If there is an interrupt on a input pin detected a message with the pin values is sent to the host. <br>
Note: Debouncing is not prevented. <br>
Note: The output pins are set to the given values from the host. There is no way to only set **one** specific pin to a value.

## Timer_Unit
Can be configured via UART (No configuaration in VHDL code neccessary). <br>
The timer is a x-bit timer with x being the amount of bits of the host UART communication. <br>
It counts from a given start value (default 0) up to the maximum value of x bit. The overflow triggers an interrupt which is sent to the host. <br>
The timer frequency is at 5% of host baud rate. <br>
Note: The reason is, that that is the maximum of ExtPack packages (consists of two UART packages: unit number and unit data) that are be able to be transmitted to the host via 8N1 UART, which is the fastest supported host UART mode when looking at packages transmission rate. <br>
The speed of counting (prescaler) can also be set as a divisor of this 5% of host BAUD frequency. (default: 1) <br>
For example: With a host baud rate of 1 MHz a prescale divisor of 2 results in 25 KHz. <br>
The access mode handles all this configurations: 
 - "00": Enables/disables the timer. 
    - 0 as value disables the timer.
    - Any value greater then 0 enables the timer.
 - "01": Restarts the timer. (value is ignored)
 - "10": Sets the value as the prescale divisor. (Note: Even values lead to a preciser timer)
 - "11": Sets the value as the start value of the timer.

 Note: Think of the fact, that scheduling and sending the timer overflow interrupt to the host will need some time.

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