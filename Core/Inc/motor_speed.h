/**
 * @file motor_speed.h
 * @brief Header file for motor speed measurement using hall sensor input capture
 *
 * This module handles speed measurement using timer input capture on STM32.
 * It processes hall sensor pulses to calculate motor RPM using TIM4.
 */

#ifndef MOTOR_SPEED_H
#define MOTOR_SPEED_H

#include "stm32f7xx_hal.h"
#include <stdint.h>

/* Configuration Constants */
#define MOTOR_SPEED_HALL_PULSES_PER_REV 21   // Number of hall sensor pulses per revolution
/* Public Function Declarations */

/**
 * @brief Initialize the motor speed monitoring module
 * @param htim Pointer to TIM_HandleTypeDef structure for TIM4
 * @return HAL status
 */
HAL_StatusTypeDef MotorSpeed_Init(TIM_HandleTypeDef* htim);

/**
 * @brief Get the current motor speed in RPM
 * @return Current speed in RPM (0 if motor is stopped)
 */
float MotorSpeed_GetRPM(void);

/**
 * @brief Timer input capture callback handler
 * @param htim Pointer to TIM_HandleTypeDef structure
 * @note This should be called from HAL_TIM_IC_CaptureCallback
 */
void MotorSpeed_TimerCallback(TIM_HandleTypeDef* htim);

#endif /* MOTOR_SPEED_H */
