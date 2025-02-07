clear all
clc
load("sensor_data.mat")


% detectJumps(dataBuffer(:,1),1)
% 
% detectJumps(dataBuffer(:,2),1)


figure(2)
plot(dataBuffer(:,1))  %% Packet Counter
hold on
plot(dataBuffer(:,2))  %% Time ms
plot(dataBuffer(:,3))  %% ADC [0-4095]


detectJumps(dataBuffer(:,2),1)