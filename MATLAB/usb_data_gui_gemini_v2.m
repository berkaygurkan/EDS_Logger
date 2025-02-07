function usb_data_gui_gemini_v2()
    % Create a figure for the GUI
    fig = figure('Name', 'USB Data Acquisition Optimized', ...
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
    packetSize = 28; % Header (4 bytes) + 5 uint32_t values (20 bytes)
    % Start button callback
    function startCallback(~, ~)
    if isRunning
        set(statusText, 'String', 'Already running.');
        return;
    end
    % Configure serial port
    port = 'COM5'; % Replace with your port
    try
        s = serialport(port, 115200);
        configureTerminator(s, 'LF'); % Not used in binary mode, but required for MATLAB
    catch e
        set(statusText, 'String', ['Error opening port: ', e.message]);
        return;
    end
    % Initialize variables
    dataBuffer = [];
    byteBuffer = uint8([]);
    isRunning = true;
    set(statusText, 'String', 'Running... Press "P" to stop.');
    cnt = 0;
    packet_count = 0; % Track processed packets
    missed_header_count = 0; % Track how many times header not found
    while isRunning
        try
            % Read available bytes - non-blocking read
            if s.NumBytesAvailable > 0
                newBytes = read(s, s.NumBytesAvailable, 'uint8');
                byteBuffer = [byteBuffer; newBytes(:)]; % Append new bytes
            end
            % Process complete packets
            while numel(byteBuffer) >= packetSize
                headerIdx = findHeader(byteBuffer, header);
                if ~isempty(headerIdx)
                    if (numel(byteBuffer) >= headerIdx + packetSize - 1)
                        % Extract the packet
                        packet = byteBuffer(headerIdx:headerIdx + packetSize - 1);
                        byteBuffer(1:headerIdx + packetSize - 1) = []; % Remove processed bytes
                        % Parse the packet (skip header) - Efficient typecasting
                        values = typecast(packet(5:end), 'uint32');
                        dataBuffer = [dataBuffer; values']; % Append to data buffer
                        cnt = cnt + 1;
                        packet_count = packet_count + 1; % Increment packet counter
                    else
                        % Incomplete packet after header
                        break; % Wait for more data
                    end
                else
                    % Header not found
                    missed_header_count = missed_header_count + 1;
                    if numel(byteBuffer) > numel(header)
                        byteBuffer(1) = []; % Remove first byte to resync
                    else
                        break; % Buffer too small
                    end
                    if missed_header_count > 1000 % Safety break
                        isRunning = false;
                        break;
                    end
                    break; % Search for header again
                end
            end
            % Small delay - Adjust if needed, but likely not bottleneck if no packet loss
            pause(0.0005); % Reduced delay slightly - can test with and without
            % Stop after 5000 packets (optional)
            if cnt > 100000
                isRunning = false;
            end
        catch serial_error
            fprintf('Serial port error during read: %s\n', serial_error.message);
            set(statusText, 'String', 'Serial port error.');
            isRunning = false;
        end
    end
    % Cleanup
    if exist('s','var') && ~isempty(s)
        clear s;
    end
    save('sensor_data.mat', 'dataBuffer');
    disp(['Complete. Processed Packets: ', num2str(packet_count), ', Missed Headers: ', num2str(missed_header_count)]);
    set(statusText, 'String', 'Data saved to sensor_data.mat.');

    load("sensor_data.mat")
    
    detectJumps(dataBuffer(:,1),1)
    detectJumps(dataBuffer(:,2),1)
    %figure(2)
    %plot(dataBuffer(:,1))  %% Packet Counter
    %hold on
    %plot(dataBuffer(:,2))  %% Time ms
    %plot(dataBuffer(:,3))  %% ADC [0-4095]


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
    % Helper function to find header in byte buffer - Manual Byte Comparison - Optimized
    function headerIdx = findHeader(buffer, header)
    headerLen = numel(header);
    bufferLen = numel(buffer);
    headerIdx = []; % Initialize as not found
    if bufferLen < headerLen
        return; % Buffer too short - optimized, no fprintf here for performance in loop
    end
    for idx = 1:bufferLen - headerLen + 1
        current_segment = buffer(idx:idx+headerLen-1);
        % Manual byte-by-byte comparison - inlined for speed
        isHeader = true; % Assume header until proven otherwise
        for byteIdx = 1:headerLen
            if current_segment(byteIdx) ~= header(byteIdx)
                isHeader = false;
                break; % Exit inner loop on mismatch
            end
        end
        if isHeader
            headerIdx = idx;
            return; % Header found, exit function early
        end
    end
    end % No fprintf for "Header NOT FOUND" in optimized version for speed
end