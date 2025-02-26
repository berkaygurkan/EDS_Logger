# EDS_Logger
 One DOF EDS System STM32 and MATLAB Files


# Wiring Diagram
 
STM32F767ZIT Nucleo Board Pinout diagram is given in this [link](https://os.mbed.com/platforms/ST-Nucleo-F767ZI/).
Motor Driver Socket Diagram is given in this [link](https://flipsky.net/products/flipsky-75100-75v-100a-single-esc-based-on-vesc-for-electric-skateboard-scooter-ebike-speed-controller?_pos=2&_psq=75100&_ss=e&_v=1.0) 


## STM - Motor Driver 

This document details the wiring connections for the STM microcontroller.

### STM - Motor Driver (USART2)
--- 
These connections are necessary to send the motor's RPM and current targets via UART. Only the existing socket cables on the drive will be used. A male socket can be added to the circuit, and the connections can be transferred to the STM via the socket.

|   **STM Pin**   | **Wire Color** | **Motor Driver Pin** |
|:---------------:|:--------------:|:--------------------:|
| PD6 (USART2_RX) | Orange         | TX2                  |
| PD5 (USART2_TX) | Green          | RX2                  |
| GND             | Black          | GND                  |
| NC              | Red            | 3.3V                 |
### STM - Motor Driver - HALL Sensor

The motor driver needs HALL sensor data to control the motor speed, but in order to get this data faster, we are also reading the sensor data through the STM in the project. Currently, the sensor output is a male socket, and the motor driver input is a female socket. The following connections should be added to the existing connections and transferred to the STM while maintaining these connections. Please note that 5V will not be connected.

|     STM Pin     | Wire Color | Motor Driver Pin | HALL Sensor Pin |
|:---------------:|:----------:|:----------------:|:---------------:|
| NC              | Red        | 5V               | 5V              |
| NC              | White      | TEMP             | TEMP            |
| PD12 (TIM4_CH1) | Blue       | HALL1            | HALL1           |
| PD13 (TIM4_CH2) | Orange     | HALL2            | HALL2           |
| PD14 (TIM4_CH3) | Green      | HALL3            | HALL3           |
| GND             | Black      | GND              | GND             |

### STM - Analog Read
--- 
The connections below are arranged to read analog sensors. Please remember that in addition to each sensor's own power connection, their ground lines must be combined in the general GND.
#### STM - Panasonic

|    STM Pin    |   Connection  | Panasonic Pin |
|:-------------:|:-------------:|:-------------:|
| PA0 (ADC1_I0) | Level Shifter | ADCOUT        |
| GND           | GND           | GND           |
| NC            | 5V            | 5V            |

#### STM - Force Sensors

|     STM Pin     |  Load Cell Connection  |
| :-------------: | :--------------------: |
| PA3 (ADC1_IN3)  | Load Cell 1 Analog Out |
| PA4 (ADC1_IN4)  | Load Cell 2 Analog Out |
| PA5 (ADC1_IN5)  | Load Cell 3 Analog Out |
| PA6 (ADC1_IN6)  | Load Cell 4 Analog Out |
| PB1 (ADC1_IN9)  | Load Cell 5 Analog Out |
| PC0 (ADC1_IN10) | Load Cell 6 Analog Out |
| PC2 (ADC1_IN12) | Load Cell 7 Analog Out |
| PC3 (ADC1_IN13) | Load Cell 8 Analog Out |
|      GND*       |          GND*          |


Here, I created a pin diagram based on the worst-case scenario, assuming each load cell has a single output. 

- Additionally, I haven't specified the power connections of the sensors here, but their GND need to be connected to the STM.
### STM to MATLAB

1. **Debugging & Programming:** The onboard STM Link with a USB input is used.
2. **Data Logging:** The onboard external USB port is used.

- No additional connections are required for PC connection.
