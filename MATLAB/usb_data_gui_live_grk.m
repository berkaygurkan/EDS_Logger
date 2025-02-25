function usb_data_gui_live_grk()
% Create and run the USB Data Acquisition GUI with live visualization
% --- GUI Creation ---
fig = create_gui();

% --- GUI Components ---
handles = guihandles(fig);
handles.isRunning = false;
handles.isPaused = false; % Add for pause/resume functionality
handles.s = [];
handles.dataBuffer = zeros(0, 6);  % [PacketCounter, Time_ms, Panasonic, LoadCell, SetRPM, CurrentSpeed]
handles.byteBuffer = uint8([]);
handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);
handles.packetSize = 28;
handles.fig = fig;

% --- Live Visualization Setup ---
handles.dataPlot = axes('Parent', fig, 'Position', [0.12 0.20 0.82 0.70]); 
title(handles.dataPlot, 'Real-Time Sensor Data');
xlabel(handles.dataPlot, 'Time (ms)');
ylabel(handles.dataPlot, 'Sensor Values');
grid(handles.dataPlot, 'on');
hold(handles.dataPlot, 'on');

% Create data lines with improved styling
colors = [0 0.4470 0.7410;   % Blue
    0.8500 0.3250 0.0980; % Orange
    0.9290 0.6940 0.1250; % Yellow
    0.4940 0.1840 0.5560]; % Purple

lineStyles = {'-', '-', '-', '-'};
lineWidths = [1.5, 1.5, 1.5, 1.5];
labels = {'Panasonic (V)', 'Load Cell (N)', 'Set RPM (x1000)', 'Current Speed (x1000)'};

for i = 1:4
    handles.dataLines(i) = plot(handles.dataPlot, NaN, NaN,...
        'Color', colors(i,:),...
        'LineStyle', lineStyles{i},...
        'LineWidth', lineWidths(i),...
        'DisplayName', labels{i});
end

% Configure legend
handles.legend = legend(handles.dataPlot, 'Location', 'northeastoutside');
handles.legend.FontName = 'Consolas';
handles.legend.FontSize = 9;
handles.legend.Box = 'off';

% Visualization parameters
handles.plotWindowSize = 1000;  % Show last 1000 ms
handles.updateInterval = 0.05;  % Update plot every 50ms
handles.lastUpdateTime = 0;
handles.initialTime = NaN;

% Configure axis aesthetics
set(handles.dataPlot, 'FontName', 'Consolas', 'FontSize', 10);
set(handles.dataPlot, 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3]);
set(handles.dataPlot, 'GridColor', [0.8 0.8 0.8]);

% Enable zoom and pan for scrolling back
zoom(handles.fig, 'on');
pan(handles.fig, 'on');

% Force initial rendering
drawnow;
guidata(fig, handles);

% --- Helper Functions ---
    function fig = create_gui()
        fig = figure('Name', 'Real-Time Data Acquisition',...
            'Position', [50 50 1200 700],...
            'NumberTitle', 'off',...
            'KeyPressFcn', @keyPressCallback,...
            'CloseRequestFcn', @closeGUI,...
            'Color', [1 1 1],...
            'Renderer', 'painters');

        % Control Panel
        uipanel('Position', [0.01 0.01 0.98 0.12],...
            'Title', 'Control Panel',...
            'FontName', 'Consolas',...
            'BackgroundColor', [0.95 0.95 0.95]);

        % Start Button
        uicontrol('Style', 'pushbutton',...
            'String', 'Start Acquisition',...
            'Position', [20 20 120 30],...
            'FontName', 'Consolas',...
            'BackgroundColor', [0.8 0.9 0.8],...
            'Callback', @startCallback);

        % Stop Button
        uicontrol('Style', 'pushbutton',...
            'String', 'Stop Acquisition',...
            'Position', [150 20 120 30],...
            'FontName', 'Consolas',...
            'BackgroundColor', [0.9 0.8 0.8],...
            'Callback', @stopCallback);

        % Live Button
        uicontrol('Style', 'pushbutton',...
            'String', 'Live Data',...
            'Position', [280 20 120 30],...
            'FontName', 'Consolas',...
            'BackgroundColor', [0.9 0.8 0.8],...
            'Callback', @startLiveCallback);

        % Save Button
        uicontrol('Style', 'pushbutton',...
            'String', 'Save Data',...
            'Position', [410 20 120 30],...
            'BackgroundColor', [0.9 0.8 0.8],...
            'Callback', @saveDataCallback);

        % Pause/Resume Button
        uicontrol('Style', 'pushbutton',...
            'String', 'Pause/Resume',...
            'Position', [540 20 120 30],...
            'FontName', 'Consolas',...
            'BackgroundColor', [0.8 0.8 0.9],...
            'Callback', @pauseResumeCallback);

        % Status Text
        uicontrol('Style', 'text',...
            'Tag', 'statusText',...
            'String', 'Status: Idle',...
            'Position', [670 20 250 30],...
            'FontName', 'Consolas',...
            'FontSize', 10,...
            'HorizontalAlignment', 'left',...
            'BackgroundColor', [0.95 0.95 0.95]);

        % Packet Counter
        uicontrol('Style', 'text',...
            'Tag', 'packetCounter',...
            'String', 'Packets Received: 0',...
            'Position', [930 20 250 30],...
            'FontName', 'Consolas',...
            'FontSize', 10,...
            'HorizontalAlignment', 'right',...
            'BackgroundColor', [0.95 0.95 0.95]);
    end

    function startCallback(~, ~)
        handles = guidata(fig);
        if handles.isRunning
            set(handles.statusText, 'String', 'Already running.');
            return;
        end

        port = 'COM5'; % Replace with your COM port
        try
            handles.s = serialport(port, 115200);
            configureTerminator(handles.s, 'LF');
            fprintf(handles.s, 'L');
        catch e
            set(handles.statusText, 'String', ['Error opening port: ', e.message]);
            return;
        end

        handles.dataBuffer = zeros(0, 6);
        handles.byteBuffer = uint8([]);
        handles.isRunning = true;
        handles.isPaused = false;
        set(handles.statusText, 'String', 'Running... Press "P" to stop.');
        guidata(fig, handles);

        figure(fig);
        data_acquisition_loop();
    end

    function startLiveCallback(~, ~)
        startCallback([], []);
    end

    function stopCallback(~, ~)
        handles = guidata(fig);
        if handles.isRunning
            if ~isempty(handles.s) && isvalid(handles.s)
                fprintf(handles.s, 'T');
            end
            handles.isRunning = false;
            if isvalid(handles.statusText)
                set(handles.statusText, 'String', 'Stopped by user.');
            end
            guidata(fig, handles);
        else
            if isvalid(handles.statusText)
                set(handles.statusText, 'String', 'Not running.');
            end
        end
    end

    function saveDataCallback(~, ~)
        handles = guidata(fig);
        if ~isempty(handles.dataBuffer)
            try
                sensor_data = handles.dataBuffer;
                save('sensor_data_live.mat', 'sensor_data');
                set(handles.statusText, 'String', 'Data saved to sensor_data_live.mat');
            catch e
                set(handles.statusText, 'String', ['Error saving data: ', e.message]);
            end
        else
            set(handles.statusText, 'String', 'No data to save.');
        end
    end

    function pauseResumeCallback(~, ~)
        handles = guidata(fig);
        handles.isPaused = ~handles.isPaused;
        if handles.isPaused
            set(handles.statusText, 'String', 'Live update paused. Use zoom/pan to scroll.');
        else
            set(handles.statusText, 'String', 'Live update resumed.');
        end
        guidata(fig, handles);
    end

    function keyPressCallback(~, event)
        if strcmp(event.Key, 'p') || strcmp(event.Key, 'P')
            stopCallback([], []);
        end
    end

    function closeGUI(~, ~)
        handles = guidata(fig);
        if handles.isRunning
            stopCallback([], []);
        end
        if ~isempty(handles.s) && isvalid(handles.s)
            clear handles.s;
        end
        if isvalid(fig)
            delete(fig);
        end
    end

    function updatePlots(handles)
        if handles.isPaused
            return;
        end

        currentTime = toc;
        if currentTime - handles.lastUpdateTime < handles.updateInterval
            return;
        end
        handles.lastUpdateTime = currentTime;

        if size(handles.dataBuffer, 1) > 10
            plotData = handles.dataBuffer;

            if isnan(handles.initialTime)
                handles.initialTime = plotData(1, 2) ;
            end
            time_data = plotData(:, 2) - handles.initialTime;

            % Apply scaling factors
            plotData(:,3) = plotData(:,3) / 4095.0;
            plotData(:,4) = plotData(:,4) / 4095.0;
            plotData(:,5) = plotData(:,5) / (1000*7);
            plotData(:,6) = plotData(:,6) / 1000;

            % Determine visible data
            current_time = time_data(end);
            visibleIdx = time_data >= (current_time - handles.plotWindowSize);
            time_visible = time_data(visibleIdx);
            data_visible = plotData(visibleIdx, :);

            % Update plot lines with visible data
            set(handles.dataLines(1), 'XData', time_visible, 'YData', data_visible(:,3));
            set(handles.dataLines(2), 'XData', time_visible, 'YData', data_visible(:,4));
            set(handles.dataLines(3), 'XData', time_visible, 'YData', data_visible(:,5));
            set(handles.dataLines(4), 'XData', time_visible, 'YData', data_visible(:,6));

            % Set x-axis limits
            xlim(handles.dataPlot, [current_time - handles.plotWindowSize, current_time]);

            % Calculate y-range based on visible data
            if ~isempty(data_visible)
                yMin = min(min(data_visible(:,3:6)));
                yMax = max(max(data_visible(:,3:6)));
                if isnan(yMin) || isnan(yMax) || isinf(yMin) || isinf(yMax)
                    yRange = [0 1];
                else
                    yRange = [yMin, yMax];
                end
                margin = 0.1 * (yRange(2) - yRange(1));
                if margin == 0
                    margin = 0.1;
                end
                ylim(handles.dataPlot, yRange + [-margin margin]);
            end

            % Update packet counter
            set(handles.packetCounter, 'String',...
                sprintf('Packets Received: %d', plotData(end,1)));

            drawnow limitrate;
        end
        guidata(fig, handles);
    end

    function data_acquisition_loop()
        handles = guidata(fig);
        packet_count = 0;
        missed_header_count = 0;

        indicator = text(handles.dataPlot, 0.95, 0.95, '●',...
            'Units', 'normalized', 'Color', 'r', 'FontSize', 16,...
            'HorizontalAlignment', 'center');
        indicator_state = false;

        tic;
        handles.lastUpdateTime = 0;

        while handles.isRunning
            try
                indicator_state = ~indicator_state;
                if indicator_state
                    set(indicator, 'Color', 'g');
                else
                    set(indicator, 'Color', 'r');
                end

                if ~isempty(handles.s) && isvalid(handles.s) && handles.s.NumBytesAvailable > 0
                    newBytes = read(handles.s, handles.s.NumBytesAvailable, 'uint8');
                    handles.byteBuffer = [handles.byteBuffer; newBytes(:)];
                end

                while numel(handles.byteBuffer) >= handles.packetSize
                    headerIdx = findHeader(handles.byteBuffer, handles.header);
                    if ~isempty(headerIdx)
                        if (numel(handles.byteBuffer) >= headerIdx + handles.packetSize - 1)
                            packet = handles.byteBuffer(headerIdx:headerIdx + handles.packetSize - 1);
                            handles.byteBuffer(1:headerIdx + handles.packetSize - 1) = [];

                            packet_info = typecast(packet(5:8), 'uint32');
                            values = typecast(packet(9:end), 'uint32');
                            packet_data = [packet_info(:); values(:)];

                            handles.dataBuffer = [handles.dataBuffer; packet_data'];
                            %packet_count = packet_count + 1;
                            packet_count = handles.dataBuffer(1);

                            if packet_count <= 3
                                disp(['Packet ', num2str(packet_count), ' found at index ',...
                                    num2str(headerIdx), ', data: ', num2str(packet_data')]);
                            end
                        else
                            break;
                        end
                    else
                        missed_header_count = missed_header_count + 1;
                        if numel(handles.byteBuffer) > numel(handles.header)
                            handles.byteBuffer(1) = [];
                        else
                            break;
                        end

                        if missed_header_count > 1000
                            fprintf('Warning: Too many missed headers (%d). Initial buffer: %s\n',...
                                missed_header_count, mat2str(handles.byteBuffer(1:min(20,end))));
                            handles.isRunning = false;
                            set(handles.statusText, 'String', 'Too many header losses - stopped.');
                            guidata(fig, handles);
                            break;
                        end
                    end
                end

                updatePlots(handles);
                guidata(fig, handles);
                pause(0.005);
                handles = guidata(fig);

                if ~handles.isRunning
                    break;
                end

            catch err
                fprintf('Error: %s\n', err.message);
                if isvalid(handles.statusText)
                    set(handles.statusText, 'String', ['Error: ', err.message]);
                end
                handles.isRunning = false;
                guidata(fig, handles);
                break;
            end
        end

        if ~isempty(handles.s) && isvalid(handles.s)
            clear handles.s;
            handles.s = [];
        end

        if isvalid(indicator)
            delete(indicator);
        end

        disp(['Complete. Processed Packets: ', num2str(packet_count),...
            ', Missed Headers: ', num2str(missed_header_count)]);
        if isvalid(handles.statusText)
            set(handles.statusText, 'String', ['Data acquisition complete. ',...
                num2str(packet_count), ' packets processed.']);
        end
        guidata(fig, handles);
    end

    function headerIdx = findHeader(buffer, header)
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