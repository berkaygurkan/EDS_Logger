#ifndef HX711_H
#define HX711_H

#include "stm32f7xx_hal.h" // Adjust this include based on your STM32 series, e.g., stm32f1xx_hal.h


// GPIO port ve pin tanımlamaları
#define LOADCELL_DOUT_PORT GPIOD
#define LOADCELL_DOUT_PIN GPIO_PIN_15
#define LOADCELL_SCK_PORT GPIOB
#define LOADCELL_SCK_PIN GPIO_PIN_9


typedef struct {
    GPIO_TypeDef* PD_SCK_PORT;  // Power Down and Serial Clock Input Port
    uint16_t PD_SCK_PIN;        // Power Down and Serial Clock Input Pin
    GPIO_TypeDef* DOUT_PORT;    // Serial Data Output Port
    uint16_t DOUT_PIN;          // Serial Data Output Pin
    uint8_t GAIN;               // Amplification factor (1, 2, or 3 pulses)
    int32_t OFFSET;             // Used for tare weight
    float SCALE;                // Used to convert raw data to units
} HX711;

// Function prototypes
void HX711_Init(HX711* hx, GPIO_TypeDef* dout_port, uint16_t dout_pin,
                GPIO_TypeDef* pd_sck_port, uint16_t pd_sck_pin, uint8_t gain);
uint8_t HX711_IsReady(HX711* hx);
void HX711_WaitReady(HX711* hx, uint32_t delay_ms);
uint8_t HX711_WaitReadyRetry(HX711* hx, int retries, uint32_t delay_ms);
uint8_t HX711_WaitReadyTimeout(HX711* hx, uint32_t timeout, uint32_t delay_ms);
void HX711_SetGain(HX711* hx, uint8_t gain);
int32_t HX711_Read(HX711* hx);
int32_t HX711_ReadAverage(HX711* hx, uint8_t times);
double HX711_GetValue(HX711* hx, uint8_t times);
float HX711_GetUnits(HX711* hx, uint8_t times);
void HX711_Tare(HX711* hx, uint8_t times);
void HX711_SetScale(HX711* hx, float scale);
float HX711_GetScale(HX711* hx);
void HX711_SetOffset(HX711* hx, int32_t offset);
int32_t HX711_GetOffset(HX711* hx);
void HX711_PowerDown(HX711* hx);
void HX711_PowerUp(HX711* hx);
int32_t getHX711(void);
#endif /* HX711_H */
