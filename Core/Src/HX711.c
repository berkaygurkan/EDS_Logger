#include "HX711.h"


extern TIM_HandleTypeDef htim2;

// Private function to approximate microsecond delays
static void delay_microseconds(uint32_t us) {
	  __HAL_TIM_SET_COUNTER(&htim2, 0);
	  while (__HAL_TIM_GET_COUNTER(&htim2) < us);

}

void HX711_Init(HX711* hx, GPIO_TypeDef* dout_port, uint16_t dout_pin,
                GPIO_TypeDef* pd_sck_port, uint16_t pd_sck_pin, uint8_t gain) {
    hx->DOUT_PORT = dout_port;
    hx->DOUT_PIN = dout_pin;
    hx->PD_SCK_PORT = pd_sck_port;
    hx->PD_SCK_PIN = pd_sck_pin;
    hx->OFFSET = 0;
    hx->SCALE = 1.0f;


    HX711_SetGain(hx, gain);
}

uint8_t HX711_IsReady(HX711* hx) {
    return HAL_GPIO_ReadPin(hx->DOUT_PORT, hx->DOUT_PIN) == GPIO_PIN_RESET;
}

void HX711_SetGain(HX711* hx, uint8_t gain) {
    switch (gain) {
        case 128: hx->GAIN = 1; break; // Channel A, gain 128
        case 64:  hx->GAIN = 3; break; // Channel A, gain 64
        case 32:  hx->GAIN = 2; break; // Channel B, gain 32
        default:  hx->GAIN = 1; break; // Default to 128
    }
}

/*int32_t HX711_Read(HX711* hx) {
    HX711_WaitReady(hx, 0);

    uint8_t data[3] = {0};
    uint8_t filler;

    // Disable interrupts to prevent timing issues during read
    __disable_irq();

    // Read 24 bits (3 bytes), MSBFIRST
    for (int j = 2; j >= 0; j--) {
        for (uint8_t i = 0; i < 8; i++) {
            HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_SET);
            delay_microseconds(1);
            data[j] |= (HAL_GPIO_ReadPin(hx->DOUT_PORT, hx->DOUT_PIN) == GPIO_PIN_SET) << (7 - i);
            HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_RESET);
            delay_microseconds(1);
        }
    }

    // Set gain/channel for next reading
    for (uint8_t i = 0; i < hx->GAIN; i++) {
        HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_SET);
        delay_microseconds(1);
        HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_RESET);
        delay_microseconds(1);
    }

    __enable_irq();

    // Sign-extend the 24-bit value to 32 bits
    filler = (data[2] & 0x80) ? 0xFF : 0x00;
    int32_t value = ((int32_t)filler << 24) |
                    ((int32_t)data[2] << 16) |
                    ((int32_t)data[1] << 8) |
                    (int32_t)data[0];

    return value;
}
*/

void HX711_WaitReady(HX711* hx, uint32_t delay_ms) {
    while (!HX711_IsReady(hx)) {
        HAL_Delay(delay_ms);
    }
}

uint8_t HX711_WaitReadyRetry(HX711* hx, int retries, uint32_t delay_ms) {
    int count = 0;
    while (count < retries) {
        if (HX711_IsReady(hx)) return 1;
        HAL_Delay(delay_ms);
        count++;
    }
    return 0;
}

uint8_t HX711_WaitReadyTimeout(HX711* hx, uint32_t timeout, uint32_t delay_ms) {
    uint32_t start = HAL_GetTick();
    while (HAL_GetTick() - start < timeout) {
        if (HX711_IsReady(hx)) return 1;
        HAL_Delay(delay_ms);
    }
    return 0;
}

int32_t HX711_ReadAverage(HX711* hx, uint8_t times) {
    int32_t sum = 0;
    for (uint8_t i = 0; i < times; i++) {
        sum += HX711_Read(hx);
    }
    return sum / times;
}

double HX711_GetValue(HX711* hx, uint8_t times) {
    return (double)HX711_ReadAverage(hx, times) - hx->OFFSET;
}

float HX711_GetUnits(HX711* hx, uint8_t times) {
    return (float)HX711_GetValue(hx, times) / hx->SCALE;
}

void HX711_Tare(HX711* hx, uint8_t times) {
    HX711_SetOffset(hx, HX711_ReadAverage(hx, times));
}

void HX711_SetScale(HX711* hx, float scale) {
    hx->SCALE = scale;
}

float HX711_GetScale(HX711* hx) {
    return hx->SCALE;
}

void HX711_SetOffset(HX711* hx, int32_t offset) {
    hx->OFFSET = offset;
}

int32_t HX711_GetOffset(HX711* hx) {
    return hx->OFFSET;
}

void HX711_PowerDown(HX711* hx) {
    HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_SET);
}

void HX711_PowerUp(HX711* hx) {
    HAL_GPIO_WritePin(hx->PD_SCK_PORT, hx->PD_SCK_PIN, GPIO_PIN_RESET);
}




int32_t HX711_Read(HX711* hx) {


	  int32_t data = 0;
	  HX711_WaitReady(hx, 0);

	  //uint32_t startTime = HAL_GetTick();
	  /*while(HAL_GPIO_ReadPin(LOADCELL_DOUT_PORT, LOADCELL_DOUT_PIN) == GPIO_PIN_SET)
	  {
	    if(HAL_GetTick() - startTime > 200)
	      return 0;
	  }*/
	  for(int8_t len=0; len<24 ; len++)
	  {
	    HAL_GPIO_WritePin(LOADCELL_SCK_PORT, LOADCELL_SCK_PIN, GPIO_PIN_SET);
	    delay_microseconds(1);
	    data = data << 1;
	    HAL_GPIO_WritePin(LOADCELL_SCK_PORT, LOADCELL_SCK_PIN, GPIO_PIN_RESET);
	    delay_microseconds(1);
	    if(HAL_GPIO_ReadPin(LOADCELL_DOUT_PORT, LOADCELL_DOUT_PIN) == GPIO_PIN_SET)
	      data ++;
	  }
	  data = data ^ 0x800000;
	  HAL_GPIO_WritePin(LOADCELL_SCK_PORT, LOADCELL_SCK_PIN, GPIO_PIN_SET);
	  delay_microseconds(1);
	  HAL_GPIO_WritePin(LOADCELL_SCK_PORT, LOADCELL_SCK_PIN, GPIO_PIN_RESET);
	  delay_microseconds(1);
	  return data;

}




