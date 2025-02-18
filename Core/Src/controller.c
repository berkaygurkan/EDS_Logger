#include "math.h"
#include "main.h"
#include "data_acquisition.h"


// PID Controller Structure
typedef struct {
    float Kp;      // Proportional gain
    float Ki;      // Integral gain
    float Kd;      // Derivative gain
    float Ts;      // Sampling time (1/1000 = 0.001 for 1kHz)

    float integral; // Integral term
    float prev_error; // Previous error
    float prev_derivative; // Previous derivative (for derivative filter)
    float derivative_filter_coeff; //Coefficient for derivative filter
} PID_Controller;

// Initialize PID controller parameters
void PID_Init(PID_Controller *pid, float Kp, float Ki, float Kd, float Ts, float derivative_filter_cutoff_freq) {
    pid->Kp = Kp;
    pid->Ki = Ki;
    pid->Kd = Kd;
    pid->Ts = Ts;
    pid->integral = 0;
    pid->prev_error = 0;
    pid->prev_derivative = 0;

    // Derivative filter coefficient calculation (Tustin/Bilinear transform)
    // A simple first-order low-pass filter for derivative action.
    // Cutoff frequency is important to avoid noise amplification.
    float wc = 2.0f * M_PI * derivative_filter_cutoff_freq;  // Cutoff angular frequency
    pid->derivative_filter_coeff = 1.0f / (1.0f + wc * pid->Ts);
}


// PID controller calculation function
float PID_Compute(PID_Controller *pid, float setpoint, float process_variable) {
    float error = setpoint - process_variable;

    // Proportional term
    float proportional = pid->Kp * error;

    // Integral term (Tustin/Bilinear discretization)
    pid->integral += (pid->Ki * pid->Ts / 2.0f) * (error + pid->prev_error);

    //Anti-windup (optional but highly recommended):
    float integral_limit = 1000.0f; //Example limit. Tune this!
    if (pid->integral > integral_limit) {
        pid->integral = integral_limit;
    } else if (pid->integral < -integral_limit) {
        pid->integral = -integral_limit;
    }


    // Derivative term (Tustin/Bilinear discretization with filter)
    float derivative = (2.0f * pid->Kd / pid->Ts) * (error - pid->prev_error);

    // Apply derivative filter (important for noise reduction)
    float filtered_derivative = pid->derivative_filter_coeff * derivative + (1.0f - pid->derivative_filter_coeff) * pid->prev_derivative;

    pid->prev_derivative = filtered_derivative; //Save the filtered derivative

    // PID output
    float output = proportional + pid->integral + filtered_derivative;

    pid->prev_error = error; // Store current error for next iteration

    return output;
}



float sine1 = 0;
float sine2 = 0;
float f_sine =0.2f;
float sine_bias = 5000.0f;
float sine_amplitude = 1000.0f;
float set_rpm;


float Motor_Input(void)
{
	/*EXAMPLE Sine Wave */
	float time = Get_MilliSecond()/1000.0f; // Time in seconds
	sine1 = sinf(2*M_PI*f_sine*time);
	sine2 = sinf(2*M_PI*f_sine*time);
	set_rpm = sine_bias+ sine_amplitude*sine1 + sine_amplitude/2*sine2;

	return set_rpm;
}
