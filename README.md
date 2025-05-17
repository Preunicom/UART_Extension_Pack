# UART Extension Pack (ExtPack)

## Features
The ExtPack is able to add units (like GPIO, Timer or UART) to a UART capable device.

## Communication with Host
The ExtPack communicates with the host over UART.  
The communication with the host has to be at least 8 data bits.
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

### Define host communication
Set the default values of Main_Unit to your specific UART configuration of your host.  
**Note:** Make sure you have >= 8 data bits for your host communication as well as a BAUD rate less or equal of half your FPGA frequency

## Special Units
### Reset Unit
The unit zero is the reset unit. This unit tells the host if the ExtPack got reset with the highest possible unit data value.  
Additionally, it is possible to reset the ExtPack by sending the highest possible unit data value to unit zero.

### Error Unit
The unit one is the error unit. It handles errors of all units and sends status messages to the host about these errors.  
The message structure is shown in the following:
- Bit 0: Indicates a UART error when receiving UART data from the host.
- Bit 1: Indicates an error of any unit while sending data to host. (for example because of too slow scheduling)
- Bit 2: Indicates an error of any unit while processing data from the host. (for example when the UART Unit can not send data as the unit still processes the last data)
All other bits are zero.

## Custom Units
### UART_Unit
Can be configured with BAUD rate, data bits, stop bits and parity bit.  
Needs two pins (rx and tx) of the FPGA.  
BAUD has to be less or equal than the FPGA frequency. 
**Note:** Integer divisor baud rates lead to more stable UART communication  
Data bits have to be more than 5 and all bits (stop, data and parity) have to be less or equal 15.  
Normally: 
  - data bits: 5-9
  - stop bits: 1-2
  - parity bit: 0-1

UART messages are directly forwarded from unit to the host or from the host to the unit.  
Access mode is ignored.  
**Note:** UART messages with parity or frame errors are ignored!  
**Note:** If there is too much traffic on the ExtPack and UART Unit has to less priority and is receiving too much load it is possible that UART packages are getting lost because it is scheduled too slow or never because of starvation.
The system operates on a Best-Effort Delivery basis, meaning it strives to transmit data as efficiently as possible but does not guarantee delivery.

### SPI_Unit
Can be configured with data rate, amount slaves, SPI mode, LSB or MSB and the amount of data bits per message.  
The SPI_FREQ_HZ has to be lower or equal to half of the IN_FREQ_HZ.  
Available SPI_MODEs are 0-3.  
LEAST_SIG_BIT_FIRST is a boolean value (1 = LSB, 0 = MSB).  
DATA_BITS have to be less or equal to 14.  
It needs following pins:  

- SCK pin
- CS pins (amount is set in the configuration)
- MISO pin
- MOSI pin

The access mode handles data sending and the current slave ID:

- "*0": Sends a message to the set slave.
- "*1": Sets slave to communicate with.

There are three situations where errors are forwarded to the Error_Unit:

- Too slow scheduling (error_to_host)
- Sending command while SPI_Unit not ready (error_from_host)
- Slave ID set command with invalid slave ID (error_from_host)

### GPIO_Unit
Can be configured with in and out pin amount.  
Pin amount has to be at least 1 and maximum the amount of data bits of the host UART communication.
The access mode controls the type of pins.
  - "00" or "10": Set output pins
  - "01" or "11": Request values of input pins

If there is an interrupt on a input pin detected a message with the current pin values is sent to the host.  
**Note:** Debouncing is not prevented. Therefore its possible to lose interrupts if they are faster than the scheduling and the UART transmission to the host.  
**Note:** The output pins are set to the given values from the host. There is no way to only set **one** specific pin to a value.

## Timer_Unit
Can be configured via UART (No configuration in VHDL code necessary).  
The timer is an x-bit timer with x being the amount of bits of the host UART communication.  
It counts from a given start value (default 0) up to the maximum value of x bit. The overflow triggers an interrupt which is sent to the host.  
The timer frequency is at 5% of host baud rate.  
**Note:** The reason is, that that is the maximum of ExtPack packages (consists of two UART packages: unit number and unit data) that are being able to be transmitted to the host via 8N1 UART, which is the fastest supported host UART mode when looking at packages transmission rate.  
The speed of counting (prescaler) can also be set as a divisor of this 5% of host BAUD frequency. (default: 1)  
For example: With a host baud rate of 1 MHz a prescale divisor of 2 results in 25 KHz.  
The access mode handles all this configurations: 
 - "00": Enables/disables the timer. 
    - 0 as value disables the timer.
    - Any value greater than 0 enables the timer.
 - "01": Restarts the timer. (value is ignored)
 - "10": Sets the value as the prescale divisor. (**Note:** Even values lead to a preciser timer)
 - "11": Sets the value as the start value of the timer.

 **Note:** Think of the fact, that scheduling and sending the timer overflow interrupt to the host will need some time.  
 **Note:** As the timer counts even if disabled, because disabling only targets the interrupt, you have to restart the timer to apply the set start value and get the result as expected.  
 
 **Timer init suggestion:**
 1) set prescale factor and or start value (the order doesn't matter if the timer is restarted afterwards)
 2) restart the timer
 3) enable the timer

**Timer change suggestion:**
 1) disable the timer
 2) init the timer like described above


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