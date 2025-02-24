clear all
clc
load("sensor_data_live.mat")



myDataBuffer = sensor_data;

cnt = myDataBuffer(:,1);
time_ms = myDataBuffer(:,2);
adc_1 = myDataBuffer(:,3);
motor_rpm = myDataBuffer(:,5)/7000;
motor_cmd = myDataBuffer(:,6)/1000;

figure(2)
plot(time_ms,motor_rpm);
hold on
plot(time_ms,motor_cmd,"LineWidth",1);
legend("Actual","Reference")


figure(3)
plot(time_ms,cnt);



detectJumps(myDataBuffer(:,2),1)