clear all
clc
load("sensor_data_final.mat")

cnt = myDataBuffer(:,1);
time_ms = myDataBuffer(:,2);
adc_1 = myDataBuffer(:,3);
motor_rpm = myDataBuffer(:,11)/1000;
motor_cmd = myDataBuffer(:,10)/1000;

figure(2)
plot(time_ms,motor_rpm);
hold on
plot(time_ms,motor_cmd/7,"LineWidth",1);
legend("Actual","Reference")


figure(3)
plot(time_ms,cnt);



detectJumps(myDataBuffer(:,2),1)