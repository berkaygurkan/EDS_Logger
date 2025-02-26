clear all;      % Clear all variables from the workspace
clc;          % Clear the command window

% Load the saved data from the .mat file.  It's good practice to include
% the full path if the file isn't in the current working directory. For
% example:
% load('path/to/your/file/sensor_data_final_2025-02-26_11-47-37.mat'); 
load("sensor_data_final_2025-02-26_11-47-37.mat");

% Convert the myDataBuffer to double precision. This is important for
% calculations and plotting.
myDataBuffer = double(myDataBuffer);

% Extract data columns.  Using descriptive variable names improves
% readability.
packet_counter = myDataBuffer(:,1);   % Packet counter
time_ms = myDataBuffer(:,2);          % Time in milliseconds
time_s = time_ms / 1000;             % Time in seconds
adc_1 = myDataBuffer(:,3);           % ADC channel 1 data (Panasonic)
% ... other ADC data if needed ...
motor_rpm = myDataBuffer(:,11) / 1000; % Motor RPM (scaled)
motor_cmd = myDataBuffer(:,10) / 7000; % Motor command (scaled)

% Create a new figure (Figure 2).  Using a figure number helps manage
% multiple figures.
figure(1);

% Plot the motor RPM.
plot(time_s, motor_rpm);
hold on;  % Keep the current plot so we can add more data

% Plot the motor command.  The division by 7 is probably a scaling factor.
plot(time_s, motor_cmd, "LineWidth", 1);

% Add a legend to the plot to identify the lines.
legend("Actual", "Reference");  % Or "Motor RPM", "Motor Command" for better clarity

% Add labels and title to the plot for better understanding.
xlabel("Time (s)");
ylabel("Motor Speed/Command");  % Be more descriptive
title("Motor RPM vs. Command");

% It's often helpful to add a grid for easier reading of values.
grid on;

% Optionally, you can control the axis limits for better visualization:
% xlim([0, time_s(end)]); % Set x-axis limits from 0 to the last time value
% ylim([min(motor_rpm), max(motor_rpm)]); % Set y-axis limits based on data

% hold off; % Release the plot hold if you're going to create more plots later.