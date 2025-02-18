/**
 * @file motor_speed.c
 * @brief Implementation of motor speed measurement using hall sensor input capture
 */

#include "motor_speed.h"

/* Private variables */
static TIM_HandleTypeDef* motor_timer;        // Timer handle
static uint32_t last_capture = 0;             // Last captured timer value
static uint32_t pulse_period = 0;             // Period between pulses
static volatile float current_rpm = 0.0f;              // Calculated RPM value

/* Private function prototypes */
static uint32_t MotorSpeed_CalculatePeriod(uint32_t current_capture);

/**
 * @brief Initialize the motor speed monitoring module
 */
HAL_StatusTypeDef MotorSpeed_Init(TIM_HandleTypeDef* htim)
{
    if (htim == NULL || htim->Instance != TIM4) {
        return HAL_ERROR;
    }

    motor_timer = htim;
    last_capture = 0;
    pulse_period = 0;
    current_rpm = 0.0f;

    return HAL_OK;
}

/**
 * @brief Get the current motor speed in RPM
 */
float MotorSpeed_GetRPM(void)
{
    return current_rpm;
}

/**
 * @brief Calculate time period between two captures, handling timer overflow
 */
static uint32_t MotorSpeed_CalculatePeriod(uint32_t current_capture)
{
    if (current_capture > last_capture) {
        return current_capture - last_capture;
    } else {
        // Handle timer overflow
        return (0xFFFF - last_capture) + current_capture;
    }
}

/**
 * @brief Timer input capture callback handler
 */
void MotorSpeed_TimerCallback(TIM_HandleTypeDef* htim)
{
    if (htim->Instance != TIM4) {
        return;
    }

    uint32_t current_capture = 0;

    // Determine which channel triggered the interrupt
    switch (htim->Channel) {
        case HAL_TIM_ACTIVE_CHANNEL_1:
            current_capture = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1);
            break;

        case HAL_TIM_ACTIVE_CHANNEL_2:
            current_capture = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_2);
            break;

        case HAL_TIM_ACTIVE_CHANNEL_3:
            current_capture = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_3);
            break;

        default:
            return;  // Invalid channel
    }

    // Calculate period between pulses
    pulse_period = MotorSpeed_CalculatePeriod(current_capture);
    last_capture = current_capture;

    // Calculate RPM
    if (pulse_period > 0) {
        // RPM = (60 * timer_clock) / (pulses_per_rev * pulse_period)
    	current_rpm = 60000000.0f / (MOTOR_SPEED_HALL_PULSES_PER_REV * pulse_period);
    } else {
        current_rpm = 0.0f;  // Motor stopped
    }
}
