################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/Src/bldc_interface.c \
../Core/Src/bldc_interface_uart.c \
../Core/Src/buffer.c \
../Core/Src/controller.c \
../Core/Src/crc.c \
../Core/Src/data_acquisition.c \
../Core/Src/main.c \
../Core/Src/motor_speed.c \
../Core/Src/packet.c \
../Core/Src/stm32f7xx_hal_msp.c \
../Core/Src/stm32f7xx_it.c \
../Core/Src/syscalls.c \
../Core/Src/sysmem.c \
../Core/Src/system_stm32f7xx.c \
../Core/Src/usb_comm.c 

OBJS += \
./Core/Src/bldc_interface.o \
./Core/Src/bldc_interface_uart.o \
./Core/Src/buffer.o \
./Core/Src/controller.o \
./Core/Src/crc.o \
./Core/Src/data_acquisition.o \
./Core/Src/main.o \
./Core/Src/motor_speed.o \
./Core/Src/packet.o \
./Core/Src/stm32f7xx_hal_msp.o \
./Core/Src/stm32f7xx_it.o \
./Core/Src/syscalls.o \
./Core/Src/sysmem.o \
./Core/Src/system_stm32f7xx.o \
./Core/Src/usb_comm.o 

C_DEPS += \
./Core/Src/bldc_interface.d \
./Core/Src/bldc_interface_uart.d \
./Core/Src/buffer.d \
./Core/Src/controller.d \
./Core/Src/crc.d \
./Core/Src/data_acquisition.d \
./Core/Src/main.d \
./Core/Src/motor_speed.d \
./Core/Src/packet.d \
./Core/Src/stm32f7xx_hal_msp.d \
./Core/Src/stm32f7xx_it.d \
./Core/Src/syscalls.d \
./Core/Src/sysmem.d \
./Core/Src/system_stm32f7xx.d \
./Core/Src/usb_comm.d 


# Each subdirectory must supply rules for building sources it contributes
Core/Src/%.o Core/Src/%.su Core/Src/%.cyclo: ../Core/Src/%.c Core/Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32F767xx -c -I../Core/Inc -I../Drivers/STM32F7xx_HAL_Driver/Inc -I../Drivers/STM32F7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Drivers/CMSIS/Include -I../USB_DEVICE/App -I../USB_DEVICE/Target -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-Core-2f-Src

clean-Core-2f-Src:
	-$(RM) ./Core/Src/bldc_interface.cyclo ./Core/Src/bldc_interface.d ./Core/Src/bldc_interface.o ./Core/Src/bldc_interface.su ./Core/Src/bldc_interface_uart.cyclo ./Core/Src/bldc_interface_uart.d ./Core/Src/bldc_interface_uart.o ./Core/Src/bldc_interface_uart.su ./Core/Src/buffer.cyclo ./Core/Src/buffer.d ./Core/Src/buffer.o ./Core/Src/buffer.su ./Core/Src/controller.cyclo ./Core/Src/controller.d ./Core/Src/controller.o ./Core/Src/controller.su ./Core/Src/crc.cyclo ./Core/Src/crc.d ./Core/Src/crc.o ./Core/Src/crc.su ./Core/Src/data_acquisition.cyclo ./Core/Src/data_acquisition.d ./Core/Src/data_acquisition.o ./Core/Src/data_acquisition.su ./Core/Src/main.cyclo ./Core/Src/main.d ./Core/Src/main.o ./Core/Src/main.su ./Core/Src/motor_speed.cyclo ./Core/Src/motor_speed.d ./Core/Src/motor_speed.o ./Core/Src/motor_speed.su ./Core/Src/packet.cyclo ./Core/Src/packet.d ./Core/Src/packet.o ./Core/Src/packet.su ./Core/Src/stm32f7xx_hal_msp.cyclo ./Core/Src/stm32f7xx_hal_msp.d ./Core/Src/stm32f7xx_hal_msp.o ./Core/Src/stm32f7xx_hal_msp.su ./Core/Src/stm32f7xx_it.cyclo ./Core/Src/stm32f7xx_it.d ./Core/Src/stm32f7xx_it.o ./Core/Src/stm32f7xx_it.su ./Core/Src/syscalls.cyclo ./Core/Src/syscalls.d ./Core/Src/syscalls.o ./Core/Src/syscalls.su ./Core/Src/sysmem.cyclo ./Core/Src/sysmem.d ./Core/Src/sysmem.o ./Core/Src/sysmem.su ./Core/Src/system_stm32f7xx.cyclo ./Core/Src/system_stm32f7xx.d ./Core/Src/system_stm32f7xx.o ./Core/Src/system_stm32f7xx.su ./Core/Src/usb_comm.cyclo ./Core/Src/usb_comm.d ./Core/Src/usb_comm.o ./Core/Src/usb_comm.su

.PHONY: clean-Core-2f-Src

