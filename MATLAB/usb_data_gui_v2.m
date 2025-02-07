function usb_data_gui_v2()
    % Create a figure for the GUI
    fig = figure('Name', 'USB Data Acquisition', ...
                 'NumberTitle', 'off', ...
                 'KeyPressFcn', @keyPressCallback);

    % Add a start button
    startButton = uicontrol('Style', 'pushbutton', ...
                            'String', 'Start', ...
                            'Position', [20 50 100 30], ...
                            'Callback', @startCallback);

    % Add a stop button
    stopButton = uicontrol('Style', 'pushbutton', ...
                           'String', 'Stop', ...
                           'Position', [140 50 100 30], ...
                           'Callback', @stopCallback);

    % Add a text box for status
    statusText = uicontrol('Style', 'text', ...
                           'String', 'Idle', ...
                           'Position', [20 100 220 30], ...
                           'FontSize', 12);

    % Global variables
    isRunning = false; % Flag to control the loop
    s = []; % Serial port object
    dataBuffer = []; % Store parsed data
    byteBuffer = uint8([]); % Accumulate raw bytes
    header = uint8([0xAA, 0xBB, 0xCC, 0xDD]); % Header to identify packets
    packetSize = 24; % Header (4 bytes) + 5 uint32_t values (20 bytes)

    % Start button callback
    function startCallback(~, ~)
        if isRunning
            set(statusText, 'String', 'Already running.');
            return;
        end

        % Configure serial port
        port = 'COM5'; % Replace with your port
        s = serialport(port, 115200);
        configureTerminator(s, 'LF'); % Not used in binary mode, but required for MATLAB

        % Initialize variables
        dataBuffer = [];
        byteBuffer = uint8([]);
        isRunning = true;
        set(statusText, 'String', 'Running... Press "P" to stop.');

        % Start reading data
        cnt = 0;
        while isRunning
            % Read available bytes
            if s.NumBytesAvailable > 0
                newBytes = read(s, s.NumBytesAvailable, 'uint8');
                byteBuffer = [byteBuffer; newBytes(:)]; % Append new bytes

                % Process complete packets
                while numel(byteBuffer) >= packetSize
                    % Search for header (allowing overlaps)
                    headerIdx = findHeader(byteBuffer, header);
                    
                    if ~isempty(headerIdx) && (numel(byteBuffer) >= headerIdx + packetSize - 1)
                        % Extract the packet
                        packet = byteBuffer(headerIdx:headerIdx + packetSize - 1);
                        byteBuffer(1:headerIdx + packetSize - 1) = []; % Remove processed bytes

                        % Parse the packet (skip header)
                        values = typecast(packet(5:end), 'uint32'); % Convert to uint32
                        dataBuffer = [dataBuffer; values']; % Append to data buffer
                        cnt = cnt + 1;
                    else
                        % Incomplete packet, wait for more data
                        break;
                    end
                end
            end

            % Small delay to avoid CPU overload
            pause(0.001);

            % Stop after 5000 packets (optional)
            if cnt > 5000
                isRunning = false;
            end
        end

        % Cleanup
        clear s;
        save('sensor_data.mat', 'dataBuffer');
        disp("Complete");
        set(statusText, 'String', 'Data saved to sensor_data.mat.');
    end

    % Stop button callback
    function stopCallback(~, ~)
        isRunning = false;
        set(statusText, 'String', 'Stopped by user.');
    end

    % Key press callback
    function keyPressCallback(~, event)
        if strcmp(event.Key, 'p') || strcmp(event.Key, 'P')
            isRunning = false;
            set(statusText, 'String', 'Stopped by "P" key.');
        end
    end

    % Helper function to find header in byte buffer
    function headerIdx = findHeader(buffer, header)
        headerLen = numel(header);
        for idx = 1:numel(buffer) - headerLen + 1
            if isequal(buffer(idx:idx+headerLen-1), header)
                headerIdx = idx;
                return;
            end
        end
        headerIdx = []; % Header not found
    end
end