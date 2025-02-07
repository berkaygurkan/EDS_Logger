function store_usb_data()
    % Cleanup previous connections
    if exist('s', 'var')
        clear s;
    end

    % Configure serial port
    port = 'COM5';  % Replace with your COM port (e.g., 'COM3')
    baudRate = 115200; % Baud rate (symbolic for USB CDC)
    s = serialport(port, baudRate);
    configureTerminator(s, 'LF'); % Match terminator sent by STM32 (e.g., '\r\n')

    % Initialize variables
    dataBuffer = []; % Dynamic buffer to store all data
    isRunning = true; % Flag to control the loop

    % Add key press listener to stop on 'P'
    fig = figure;
    set(fig, 'KeyPressFcn', @(src, event) stopOnKeyPress(event));

    % Start reading data
    disp('Reading data. Press "P" to stop...');
    while isRunning
        % Check for available data
        if s.NumBytesAvailable > 0
           
            
            % Read all available data
            newData = readline(s); % Read line-by-line (ASCII data)
            
            % Parse the line into 5 numbers (adjust format as needed)
            parsedData = sscanf(newData, '%u,%u,%u,%u,%u'); % Example: "1.23,4.56,7.89,0.12,3.45"
           
            % Append to buffer
            dataBuffer = [dataBuffer; parsedData']; % Store as rows

        end

        % Small delay to avoid CPU overload
        pause(0.01);
    end

    % Cleanup
    clear s;
    disp('Data acquisition stopped.');

    % Save data to a file
    save('sensor_data.mat', 'dataBuffer');
    disp('Data saved to sensor_data.mat.');

    % Key press callback function
    function stopOnKeyPress(event)
        if event.Character == 'p' || event.Character == 'P'
            isRunning = false; % Stop the loop
        end
    end
end