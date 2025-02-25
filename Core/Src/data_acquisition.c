/**
 * @file data_acquisition.c
 * @brief Implementation of data acquisition and buffer management
 */

#include <data_acquisition.h>
#include "main.h"
#include "motor_speed.h"
#include "bldc_interface.h"
#include "controller.h"


/* Private variables */
static volatile uint32_t usb_buffer_cnt = 0;                   // Current buffer position
static volatile uint8_t active_buffer = 0;                     // Currently active buffer
volatile uint8_t buffer_ready_flag = 0;               // Buffer ready for transmission
static volatile uint32_t time_ms = 0;                         // Time counter
extern volatile uint32_t adc_buffer[ADC_BUFFER_SIZE];
extern volatile uint32_t usb_buffer[2][ADC_BUFFER_SIZE+2][USB_BUFFER_SIZE];
/* Private function prototypes */
static void DataAcq_SwitchBuffers(void);
static uint32_t DataAcq_ScaleFloatValue(float value);

uint8_t live_mode = 0;
volatile uint8_t live_send_flag = 0;
volatile uint32_t live_buffer[5];
volatile uint8_t live_buffer_cnt = 0;

/**
 * @brief Initialize the data acquisition module
 */
HAL_StatusTypeDef DataAcq_Init(void)
{
	// Initialize counters and flags
	usb_buffer_cnt = 0;
	active_buffer = 0;
	buffer_ready_flag = 3;
	time_ms = 0;

	return HAL_OK;
}

/**
 * @brief Scale float value to uint32_t with defined scaling factor
 */
static uint32_t DataAcq_ScaleFloatValue(float value)
{
	return (uint32_t)(value * SCALING_FACTOR);
}

/**
 * @brief Switch between double buffers
 */
static void DataAcq_SwitchBuffers(void)
{
	active_buffer = 1 - active_buffer;  // Toggle between 0 and 1
	usb_buffer_cnt = 0;

	// Update buffer ready flag
	buffer_ready_flag = active_buffer ? BUFFER_STATE_READY_0 : BUFFER_STATE_READY_1;
}

/**
 * @brief Process new data samples in timer interrupt
 */
void DataAcq_ProcessSamples(TIM_HandleTypeDef* htim)
{
	if (htim->Instance != TIM3) {
		return;
	}

	// Toggle LED to indicate sampling
	//HAL_GPIO_TogglePin(GPIOB, LD1_Pin);


	// Get motor data
	float set_rpm = Motor_Input();
	bldc_interface_set_rpm(Motor_Input());
	float current_speed = MotorSpeed_GetRPM();

	// Scale float values to integers
	uint32_t scaled_set_rpm = DataAcq_ScaleFloatValue(set_rpm);
	uint32_t scaled_current_speed = DataAcq_ScaleFloatValue(current_speed);

	// Update time counter
	time_ms++;

	if (live_mode) {
		// Store in live_buffer
		live_buffer_cnt++;
		if (live_buffer_cnt % 10 == 0)
		{
			live_buffer[0] = time_ms;
			live_buffer[1] = adc_buffer[0];
			live_buffer[2] = adc_buffer[1];
			live_buffer[3] = scaled_set_rpm;
			live_buffer[4] = scaled_current_speed;
			live_buffer_cnt = 0;
			live_send_flag = 1;
		}
	}
	else if (!live_mode)
		{
		// Store data in active buffer
		usb_buffer[active_buffer][0][usb_buffer_cnt] = time_ms;
		usb_buffer[active_buffer][1][usb_buffer_cnt] = adc_buffer[0];  // Panasonic
		usb_buffer[active_buffer][2][usb_buffer_cnt] = adc_buffer[1];  // Load Cell 1
		usb_buffer[active_buffer][3][usb_buffer_cnt] = scaled_set_rpm; // Motor setpoint
		usb_buffer[active_buffer][4][usb_buffer_cnt] = scaled_current_speed; // Current speed

		// Increment buffer counter
		usb_buffer_cnt++;

		// Check if buffer is full
		if (usb_buffer_cnt >= USB_BUFFER_SIZE) {
			DataAcq_SwitchBuffers();
		}
	}

}

/**
 * @brief Get the current buffer status
 */
uint8_t DataAcq_IsBufferReady(void)
{
	return buffer_ready_flag;
}

uint32_t Get_MilliSecond(void)
{
	return time_ms;
}

/**
 * @brief Get pointer to the ready buffer for transmission
 */
uint32_t* DataAcq_GetReadyBuffer(uint32_t* buffer_size)
{
	if (!buffer_ready_flag) {
		return NULL;
	}

	*buffer_size = USB_BUFFER_SIZE * NUM_CHANNELS;
	return (uint32_t*)usb_buffer[1 - active_buffer];
}
