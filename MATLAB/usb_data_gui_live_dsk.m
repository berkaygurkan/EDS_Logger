function usb_data_gui_live()
% Create and run the USB Data Acquisition GUI with live visualization
% --- GUI Creation ---
fig = create_gui();

% --- GUI Components ---
handles = guihandles(fig); % Get handles to GUI objects
handles.isRunning = false;
handles.s = [];
handles.dataBuffer = zeros(0, 7); % Initialize dataBuffer
testBerkay = zeros(0,7);
handles.byteBuffer = uint8([]);
handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);
handles.packetSize = 28; % Header + Packet Counter + 5 Data Values (uint32_t)
handles.fig = fig; % Store the figure handle for access in all subfunctions
handles.testBerkay = zeros(0,7);


% --- Live Visualization Setup ---
handles.dataPlot = subplot(2,1,1, 'Parent', fig);
title(handles.dataPlot, 'Live Data');
xlabel(handles.dataPlot, 'Time (ms)');
ylabel(handles.dataPlot, 'Values');
hold(handles.dataPlot, 'on');
grid(handles.dataPlot, 'on');

% Create data lines for different signals
handles.dataLines = [];
% Create 5 lines with different colors
colors = {'b', 'r', 'g', 'm', 'c'};
labels = {'Time', 'Panasonic', 'Load Cell', 'Set RPM', 'Current Speed'};
for i = 1:5
    handles.dataLines(i) = plot(handles.dataPlot, 0, 0, colors{i}, 'LineWidth', 1.5);
end
legend(handles.dataPlot, labels);

% Plot for displaying buffer fill status
handles.bufferPlot = subplot(2,1,2, 'Parent', fig);
handles.bufferBar = bar(handles.bufferPlot, 0, 'FaceColor', [0.2 0.6 0.8]);
title(handles.bufferPlot, 'Buffer Fill Status');
xlabel(handles.bufferPlot, 'Buffer');
ylabel(handles.bufferPlot, 'Fill Percentage (%)');
ylim(handles.bufferPlot, [0 100]);

% Visualization parameters
handles.plotWindowSize = 1000; % Show last 1000 samples
handles.updateInterval = 0.05; % Update plot every 50ms (increased from 100ms)
handles.lastUpdateTime = 0;

% Force initial rendering to ensure plots are properly created
drawnow;

guidata(fig, handles); % Store handles in figure's user data

% --- Helper Functions ---
    function fig = create_gui()
        % Create the main figure and UI controls
        fig = figure('Name', 'USB Data Acquisition with Live Visualization', ...
            'Position', [100, 100, 1000, 700], ...
            'NumberTitle', 'off', ...
            'KeyPressFcn', @keyPressCallback, ...
            'CloseRequestFcn', @closeGUI, ...
            'Visible', 'on', ... % Ensure figure is visible
            'Renderer', 'painters'); % Use painters renderer for better performance

        % Control Panel
        uipanel('Position', [0.01 0.01 0.98 0.15], 'Title', 'Controls');

        % Start Button
        uicontrol('Style', 'pushbutton', ...
            'String', 'Start', ...
            'Position', [20 30 100 30], ...
            'Callback', @startCallback);

        % Stop Button
        uicontrol('Style', 'pushbutton', ...
            'String', 'Stop', ...
            'Position', [140 30 100 30], ...
            'Callback', @stopCallback);

        % Save Button
        uicontrol('Style', 'pushbutton', ...
            'String', 'Save Data', ...
            'Position', [260 30 100 30], ...
            'Callback', @saveDataCallback);

        % Status Text Box
        uicontrol('Style', 'text', ...
            'Tag', 'statusText',...
            'String', 'Idle', ...
            'Position', [380 30 300 30], ...
            'FontSize', 12);

        % Display packet count
        uicontrol('Style', 'text', ...
            'Tag', 'packetCounter',...
            'String', 'Packets: 0', ...
            'Position', [700 30 200 30], ...
            'FontSize', 12);
    end

    function startCallback(~, ~)
        % Callback for the Start button
        handles = guidata(fig); % Use the specific figure handle
        if handles.isRunning
            set(handles.statusText, 'String', 'Already running.');
            return;
        end

        port = 'COM5'; % Replace with your COM port
        try
            handles.s = serialport(port, 115200);
            configureTerminator(handles.s, 'LF');
            fprintf(handles.s, 'S'); % Send 'S' command to STM32
        catch e
            set(handles.statusText, 'String', ['Error opening port: ', e.message]);
            return;
        end

        handles.dataBuffer = zeros(0, 7); % Re-initialize dataBuffer at start
        handles.byteBuffer = uint8([]);
        handles.isRunning = true;
        set(handles.statusText, 'String', 'Running... Press "P" to stop.');
        guidata(fig, handles); % Update handles using fig

        % Ensure figure is visible and brought to the front
        figure(fig);

        data_acquisition_loop(); % Start data acquisition loop
    end

    function stopCallback(~, ~)
        % Callback for the Stop button
        handles = guidata(fig); % Use the specific figure handle
        if handles.isRunning
            if ~isempty(handles.s) && isvalid(handles.s)
                fprintf(handles.s, 'T'); % Send 'T' command to STM32
            end
            handles.isRunning = false;
            if isvalid(handles.statusText)
                set(handles.statusText, 'String', 'Stopped by user.');
            else
                disp('Warning: statusText handle is invalid');
            end
            guidata(fig, handles);
        else
            if isvalid(handles.statusText)
                set(handles.statusText, 'String', 'Not running.');
            else
                disp('Warning: statusText handle is invalid');
            end
        end
    end

    function saveDataCallback(~, ~)
        % Callback for the Save Data button
        handles = guidata(fig); % Use the specific figure handle
        if ~isempty(handles.dataBuffer)
            try
                sensor_data = handles.dataBuffer; % Create a variable to save
                save('sensor_data_live.mat', 'sensor_data');
                set(handles.statusText, 'String', 'Data saved to sensor_data_live.mat');
            catch e
                set(handles.statusText, 'String', ['Error saving data: ', e.message]);
            end
        else
            set(handles.statusText, 'String', 'No data to save.');
        end
    end

    function keyPressCallback(~, event)
        % Callback for key presses on the figure
        if strcmp(event.Key, 'p') || strcmp(event.Key, 'P')
            stopCallback([], []); % Call stop function
        end
    end

    function closeGUI(~, ~)
        % Callback when GUI window is closed
        handles = guidata(fig); % Use the specific figure handle
        if handles.isRunning
            stopCallback([], []); % Stop data acquisition if running
        end
        if ~isempty(handles.s) && isvalid(handles.s)
            clear handles.s;
        end
        if isvalid(fig)
            delete(fig);
        else
            disp('Warning: Figure handle is invalid, cannot delete.');
        end
    end


function data_acquisition_loop()
    % Main data acquisition loop with live visualization
    handles = guidata(fig); % Get the handles structure
    packet_count = 0;
    missed_header_count = 0;

    % Start timer for plot updates
    tic;
    handles.lastUpdateTime = 0;

    while handles.isRunning
        try
            % Read available bytes
            if handles.s.NumBytesAvailable > 0
                newBytes = read(handles.s, handles.s.NumBytesAvailable, 'uint8');
                handles.byteBuffer = [handles.byteBuffer; newBytes(:)];
            end

            % Process all complete packets in the buffer
            while numel(handles.byteBuffer) >= handles.packetSize
                headerIdx = findHeader(handles.byteBuffer, handles.header);
                if ~isempty(headerIdx)
                    if (numel(handles.byteBuffer) >= headerIdx + handles.packetSize - 1)
                        packet = handles.byteBuffer(headerIdx:headerIdx + handles.packetSize - 1);
                        handles.byteBuffer(1:headerIdx + handles.packetSize - 1) = [];

                        % Extract data
                        packet_info = typecast(packet(5:8), 'uint32');
                        values = typecast(packet(9:end), 'uint32');
                        handles.dataBuffer = [handles.dataBuffer; [double(packet_info), double(values)']];
                        packet_count = packet_count + 1;
                    else
                        break; % Incomplete packet
                    end
                else
                    % Header not found, remove first byte and try again
                    missed_header_count = missed_header_count + 1;
                    if numel(handles.byteBuffer) > numel(handles.header)
                        handles.byteBuffer(1) = []; % Remove just the first byte
                    else
                        break; % Buffer too small
                    end
                end
            end

            % Update plots with the current handles structure
            updatePlots(handles);

            % Small delay to prevent CPU hogging
            pause(0.001);

            % Get updated handles for the next loop iteration
            handles = guidata(fig);

            % Check if we should still be running
            if ~handles.isRunning
                break;
            end

        catch serial_error
            fprintf('Serial port error: %s\n', serial_error.message);
            set(handles.statusText, 'String', ['Serial error: ', serial_error.message]);
            handles.isRunning = false;
            guidata(fig, handles);
            break;
        end
    end

    % Cleanup
    if ~isempty(handles.s) && isvalid(handles.s)
        clear handles.s;
        handles.s = [];
    end

    disp(['Complete. Processed Packets: ', num2str(packet_count), ...
          ', Missed Headers: ', num2str(missed_header_count)]);
    set(handles.statusText, 'String', ['Data acquisition complete. ', ...
                          num2str(packet_count), ' packets processed.']);
    guidata(fig, handles);
end

function updatePlots(handles)
    % Update the live visualization plots
    % Use the passed handles structure instead of overwriting it
    currentTime = toc;

    % Only update every updateInterval seconds
    if currentTime - handles.lastUpdateTime < handles.updateInterval
        return;
    end

    handles.lastUpdateTime = currentTime;

    % If we have enough data, update the plots
    if size(handles.dataBuffer, 1) > 10
        % Determine the window of data to show (most recent samples)
        dataSize = size(handles.dataBuffer, 1);
        startIdx = max(1, dataSize - handles.plotWindowSize);
        plotData = handles.dataBuffer(startIdx:end, :);

        % Time data is in column 3 (after packet_info)
        time_data = plotData(:, 3);

        % Update each data line
        for i = 1:5
            if isvalid(handles.dataLines(i))
                set(handles.dataLines(i), 'XData', time_data, 'YData', plotData(:, i+2));
            end
        end

        % Update axis limits to show all the data
        if ~isempty(time_data)
            xlim(handles.dataPlot, [min(time_data), max(time_data)]);

            % Auto-adjust Y axis
            all_y_data = plotData(:, 3:7);
            ylim(handles.dataPlot, [min(all_y_data(:)), max(all_y_data(:))]);
        end

        % Update packet counter display
        packetCount = plotData(end, 2);
        set(handles.packetCounter, 'String', ['Packets: ', num2str(packetCount)]);

        % Update buffer fill bar
        bufferFillPercent = mod(dataSize, 8000) / 8000 * 100;
        set(handles.bufferBar, 'YData', bufferFillPercent);

        % Force immediate redraw with no rate limiting
        drawnow;
        figure(handles.fig); % Ensure figure is active and visible
    end

    % Store updated handles
    guidata(handles.fig, handles);
end


    function headerIdx = findHeader(buffer, header)
        % Implementing the exact header search logic from usb_data_gui
        % This iterates through each possible starting position and checks for header match
        headerLen = numel(header);
        bufferLen = numel(buffer);
        headerIdx = [];

        if bufferLen < headerLen
            return;
        end

        for idx = 1:bufferLen - headerLen + 1
            current_segment = buffer(idx:idx+headerLen-1);
            isHeader = true;
            for byteIdx = 1:headerLen
                if current_segment(byteIdx) ~= header(byteIdx)
                    isHeader = false;
                    break;
                end
            end
            if isHeader
                headerIdx = idx;
                return;
            end
        end
    end
end