#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <stdint.h>
#include <math.h> // For M_PI

// PID Controller Structure
typedef struct {
    float Kp;      // Proportional gain
    float Ki;      // Integral gain
    float Kd;      // Derivative gain
    float Ts;      // Sampling time
    float integral; // Integral term
    float prev_error; // Previous error
    float prev_derivative; // Previous derivative
    float derivative_filter_coeff; // Derivative filter coefficient
    float integral_limit; //Integral limit for anti-windup
} PID_Controller;

// Initialize PID controller parameters
void PID_Init(PID_Controller *pid, float Kp, float Ki, float Kd, float Ts, float derivative_filter_cutoff_freq, float integral_limit);

// PID controller calculation function
float PID_Compute(PID_Controller *pid, float setpoint, float process_variable);
float Motor_Input(void);
#endif // CONTROLLER_H
