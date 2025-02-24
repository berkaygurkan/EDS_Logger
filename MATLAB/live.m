function usb_data_gui()
    % Create and run the USB Data Acquisition GUI with live visualization
    % --- GUI Creation ---
    fig = create_gui();
    
    % --- GUI Components ---
    handles = guihandles(fig); % Get handles to GUI objects
    handles.isRunning = false;
    handles.s = [];
    handles.dataBuffer = zeros(0, 7); % Initialize dataBuffer
    handles.byteBuffer = uint8([]);
    handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);
    handles.packetSize = 28; % Header + Packet Counter + 5 Data Values (uint32_t)
    
    % --- Live Visualization Setup ---
    handles.dataPlot = subplot(2,1,1, 'Parent', fig);
    title(handles.dataPlot, 'Live Data');
    xlabel(handles.dataPlot, 'Time (ms)');
    ylabel(handles.dataPlot, 'Values');
    hold(handles.dataPlot, 'on');
    grid(handles.dataPlot, 'on');
    
    % Create data lines for different signals
    handles.dataLines = [];
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
    handles.updateInterval = 0.1; % Update plot every 100ms
    handles.lastUpdateTime = 0;
    
    guidata(fig, handles); % Store handles in figure's user data
    
    % --- Helper Functions ---
    function fig = create_gui()
        % Create the main figure and UI controls
        fig = figure('Name', 'USB Data Acquisition with Live Visualization', ...
            'Position', [100, 100, 1000, 700], ...
            'NumberTitle', 'off', ...
            'KeyPressFcn', @keyPressCallback, ...
            'CloseRequestFcn', @closeGUI);
        
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
        handles = guidata(gcbo); % Get handles from GUI object
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
        guidata(gcbo, handles); % Update handles
        
        data_acquisition_loop(); % Start data acquisition loop
    end

    function stopCallback(~, ~)
        % Callback for the Stop button
        handles = guidata(gcbo);
        if handles.isRunning
            fprintf(handles.s, 'T'); % Send 'T' command to STM32
            handles.isRunning = false;
            if isvalid(handles.statusText)
                set(handles.statusText, 'String', 'Stopped by user.');
            else
                disp('Warning: statusText handle is invalid');
            end
            guidata(gcbo, handles);
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
        handles = guidata(gcbo);
        if ~isempty(handles.dataBuffer)
            try
                save('sensor_data_live.mat', 'handles');
                set(handles.statusText, 'String', 'Data saved to sensor_data_live.mat');
            catch e
                set(handles.statusText, 'String', ['Error saving data: ', e.message]);
            end
        else
            set(handles.statusText, 'String', 'No data to save.');
        end
    end
end
