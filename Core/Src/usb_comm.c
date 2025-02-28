#include "usbd_cdc_if.h" // Make sure you include the necessary header for CDC functions
#include "main.h"
#include "usbd_cdc_if.h" // For CDC functions
#include "data_acquisition.h"
#include "motor_speed.h"



volatile uint8_t active_buffer = 0;
volatile uint32_t usb_buffer[2][ADC_BUFFER_SIZE+2][USB_BUFFER_SIZE];
uint32_t packet_counter = 0;
// USB Program Run Variables
uint8_t data_acquisition_running = 0; // Flag to control data acquisition
uint8_t usb_command_buffer[1]; // Buffer to receive USB commands
extern USBD_HandleTypeDef hUsbDeviceFS;

extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern TIM_HandleTypeDef htim4;

extern uint32_t time_ms;

// Assuming usb_buffer is defined like this (adjust types if needed):
// uint32_t usb_buffer[2][5][USB_BUFFER_SIZE];
// Function to transmit a single USB packet
static uint8_t transmit_usb_packet(uint32_t* data, uint16_t data_len) {
    uint8_t status;
    uint32_t start_time = HAL_GetTick();

    do {
        status = CDC_Transmit_FS((uint8_t*)data, data_len);
    } while (status != USBD_OK);

    uint32_t transmit_time = HAL_GetTick() - start_time;

    if (transmit_time > 10) {
        // Log or debug if transmit time exceeds threshold
    }
    return status; // Return the status of transmission.
}


// Function to process and transmit a buffer
static void process_and_transmit_buffer(uint8_t buffer_index, uint32_t* packet_counter) {
    for (uint16_t i = 0; i < USB_BUFFER_SIZE; i++) {
        uint32_t header = 0xddccbbaa;
        uint32_t values[7] = {
            header,
            (*packet_counter)++, // Increment and use the packet counter. Important to dereference it.
            usb_buffer[buffer_index][0][i],
            usb_buffer[buffer_index][1][i],
            usb_buffer[buffer_index][2][i],
            usb_buffer[buffer_index][3][i],
            usb_buffer[buffer_index][4][i]
        };

        transmit_usb_packet(values, sizeof(values));
    }
}


void usb_transmit_task() {
    if (buffer_ready_flag == BUFFER_STATE_READY_0) {
        process_and_transmit_buffer(0, &packet_counter);
        buffer_ready_flag = BUFFER_STATE_BUSY;
    } else if (buffer_ready_flag == BUFFER_STATE_READY_1) {
        process_and_transmit_buffer(1, &packet_counter);
        buffer_ready_flag = BUFFER_STATE_BUSY;
    }
}

uint8_t CDC_Receive_FS_App(uint8_t *Buf, uint32_t *Len)
{

  //HAL_GPIO_TogglePin(GPIOB, LD2_Pin); // Example: Toggle an LED
  USBD_CDC_SetRxBuffer(&hUsbDeviceFS, Buf); // Re-arm the receive buffer
  // Process received command
  if (*Len > 0) {
    if (Buf[0] == 'S') { // Start command
      if (!data_acquisition_running) {
        HAL_TIM_Base_Start_IT(&htim3); // Start TIM3 and interrupts
        HAL_TIM_Base_Start_IT(&htim2); // Start TIM2 and interrupts (if needed for toggling)
        data_acquisition_running = 1;
        buffer_ready_flag = 3; // Set to initial not ready value.
        packet_counter = 0; // Reset packet counter
        DataAcq_Init();
        MotorSpeed_Init(&htim4);
        active_buffer = 0;
      } else {
      }
    } else if (Buf[0] == 'T') { // Stop command
      if (data_acquisition_running) {
        HAL_TIM_Base_Stop_IT(&htim3); // Stop TIM3 and interrupts
        HAL_TIM_Base_Stop_IT(&htim2); // Stop TIM2 and interrupts
        data_acquisition_running = 0;
        buffer_ready_flag = 3; // Ensure sending loop stops gracefully
      } else {
      }
    } else {
    }
  }
  return USBD_OK;
}

