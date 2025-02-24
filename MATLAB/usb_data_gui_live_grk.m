function usb_data_gui_live_grk()
% Create and run the USB Data Acquisition GUI with live visualization
% --- GUI Creation ---
fig = create_gui();

% --- GUI Components ---
handles = guihandles(fig); % Get handles to GUI objects
handles.isRunning = false;
handles.s = [];
handles.dataBuffer = zeros(0, 6); % Initialize dataBuffer with 6 columns
handles.byteBuffer = uint8([]);
handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);
handles.packetSize = 28; % Header + Packet Counter + 5 Data Values (uint32_t)
handles.fig = fig; % Store the figure handle for access in all subfunctions

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
handles.updateInterval = 0.05; % Update plot every 50ms
handles.lastUpdateTime = 0;

% Force initial rendering to ensure plots are properly created
drawnow;

guidata(fig, handles); % Store handles in figure's user data

% --- Helper Functions ---
    function create_gui()
        fig = figure('Name', 'Data Acquisition GUI', 'Visible', 'on');
        handles.fig = fig;

        % Create subplot for data plot
        handles.dataPlot = subplot(2,1,1, 'Parent', fig);
        hold(handles.dataPlot, 'on');

        % Define colors and labels for 4 sensor values
        colors = {'b', 'r', 'g', 'k'}; % Blue, Red, Green, Black
        labels = {'Panasonic', 'Load Cell', 'Set RPM', 'Current Speed'};
        handles.dataLines = gobjects(4,1); % Array to hold 4 line objects

        % Initialize plot lines
        for i = 1:4
            handles.dataLines(i) = plot(handles.dataPlot, NaN, NaN, colors{i}, 'LineWidth', 1.5);
        end
        legend(handles.dataPlot, labels, 'Location', 'NorthWest');
        xlabel(handles.dataPlot, 'Time');
        ylabel(handles.dataPlot, 'Sensor Values');
        title(handles.dataPlot, 'Live Sensor Data');

        % Create subplot for buffer plot (if applicable)
        handles.bufferPlot = subplot(2,1,2, 'Parent', fig);
        handles.bufferBar = bar(handles.bufferPlot, 0, 0);
        xlabel(handles.bufferPlot, 'Buffer');
        ylabel(handles.bufferPlot, 'Fill Level');
        title(handles.bufferPlot, 'Buffer Status');

        % Initialize handles
        handles.isRunning = false;
        handles.dataBuffer = [];
        handles.plotWindowSize = 1000; % Number of points to display
        handles.updateInterval = 0.05; % Update every 50ms
        handles.lastUpdateTime = 0;

        % Store handles
        guidata(fig, handles);

        % Add start/stop buttons (pseudo-code, adjust as needed)
        uicontrol('Style', 'pushbutton', 'String', 'Start', 'Callback', @startCallback);
        uicontrol('Style', 'pushbutton', 'String', 'Stop', 'Callback', @stopCallback);
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

        handles.dataBuffer = zeros(0, 6); % Re-initialize dataBuffer with 6 columns
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

   function updatePlots(fig)
    handles = guidata(fig);
    currentTime = toc; % Assumes tic is called in data_acquisition_loop
    
    % Check if enough data and time to update
    dataSize = size(handles.dataBuffer, 1);
    if dataSize <= 10 || (currentTime - handles.lastUpdateTime < handles.updateInterval)
        return;
    end
    
    % Get the last 1000 samples (or all if less than 1000)
    startIdx = max(1, dataSize - handles.plotWindowSize + 1);
    plotData = handles.dataBuffer(startIdx:end, :);
    
    % Extract time and sensor data
    time_data = plotData(:, 2); % Column 2 is time
    sensor_data = plotData(:, 3:6); % Columns 3-6 are sensor values
    
    % Update each line: time vs sensor values
    for i = 1:4
        set(handles.dataLines(i), 'XData', time_data, 'YData', sensor_data(:, i));
    end
    
    % Adjust axes limits
    xlim(handles.dataPlot, [min(time_data), max(time_data)]);
    ylim(handles.dataPlot, [min(sensor_data(:)), max(sensor_data(:))]);
    
    % Force plot update
    drawnow;
    
    % Update last update time
    handles.lastUpdateTime = currentTime;
    guidata(fig, handles);
    
    % Debug output to verify execution
    disp(['Updating plot with ', num2str(length(time_data)), ' points']);
     disp(['Time range: ', num2str(min(time_data)), ' to ', num2str((max(time_data)))]);
end

    function data_acquisition_loop(fig)
    handles = guidata(fig);
    packet_count = 0;
    tic; % Start timing
    
    while handles.isRunning
        % Read packet from serial (pseudo-code, adjust as needed)
        packet = read_serial_packet(); % Your serial read function
        if ~isempty(packet)
            packet_info = typecast(packet(5:8), 'uint32'); % Packet counter
            values = typecast(packet(9:end), 'uint32');    % 5 data values
            packet_data = [double(packet_info), double(values)]';
            handles.dataBuffer = [handles.dataBuffer; packet_data];
            packet_count = packet_count + 1;
            
            % Display packet info
            disp(['Packet ', num2str(packet_count), ' found, data: ', num2str(packet_data)]);
            
            % Update plots
            updatePlots(fig);
        end
        
        % Store handles and small pause
        guidata(fig, handles);
        pause(0.005);
        handles = guidata(fig);
    end
    
    disp(['Complete. Processed Packets: ', num2str(packet_count)]);
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