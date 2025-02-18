/**
 * @file data_acquisition.h
 * @brief Header file for data acquisition and buffer management
 *
 * This module handles data collection from various sources including:
 * - Motor speed and setpoint
 * - ADC readings
 * - Timing information
 * It manages double buffering for USB transmission and data scaling.
 */

#ifndef DATA_ACQUISITION_H
#define DATA_ACQUISITION_H

#include "stm32f7xx_hal.h"

/* Configuration Constants */
#define USB_BUFFER_SIZE 8000    // Size of each buffer
#define NUM_CHANNELS    5       // Number of data channels
#define SCALING_FACTOR  1000.0f // Scaling factor for float to uint32_t conversion


extern volatile uint8_t buffer_ready_flag;


/* Buffer Status Flags */
typedef enum {
    BUFFER_STATUS_OK = 0,
    BUFFER_STATUS_ERROR,
    BUFFER_STATUS_FULL
} BufferStatus_t;

/* Public Function Declarations */

/**
 * @brief Initialize the data acquisition module
 * @return HAL status
 */
HAL_StatusTypeDef DataAcq_Init(void);

/**
 * @brief Process new data samples in timer interrupt
 * @param htim Timer handle
 */
void DataAcq_ProcessSamples(TIM_HandleTypeDef* htim);

/**
 * @brief Get the current buffer status
 * @return 1 if buffer is ready for transmission, 0 otherwise
 */

uint8_t DataAcq_IsBufferReady(void);

/**
 * @brief Get pointer to the ready buffer for transmission
 * @param buffer_size Pointer to store the buffer size
 * @return Pointer to the ready buffer, NULL if no buffer ready
 */
uint32_t* DataAcq_GetReadyBuffer(uint32_t* buffer_size);


uint32_t Get_MilliSecond(void);

#endif /* DATA_ACQUISITION_H */
