function usb_data_gui()
% Create and run the USB Data Acquisition GUI
% --- GUI Creation ---
fig = create_gui();
% --- GUI Components ---
handles = guihandles(fig); % Get handles to GUI objects
handles.isRunning = false;
handles.s = [];
handles.dataBuffer = zeros(0, 7); % Initialize dataBuffer as 0x6 matrix to enforce column number
myDataBuffer = zeros(0, 7); % Initialize dataBuffer as 0x6 matrix to enforce column number
handles.byteBuffer = uint8([]);
handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);
handles.packetSize = 28; % Header + Packet Counter + 5 Data Values (uint32_t)
guidata(fig, handles); % Store handles in figure's user data
% --- Helper Functions (nested within usb_data_gui_final for access to handles) ---
    function fig = create_gui()
        % Create the main figure and UI controls
        fig = figure('Name', 'USB Data Acquisition Final', ...
            'NumberTitle', 'off', ...
            'KeyPressFcn', @keyPressCallback, ...
            'CloseRequestFcn', @closeGUI);
        % Start Button
        uicontrol('Style', 'pushbutton', ...
            'String', 'Start', ...
            'Position', [20 50 100 30], ...
            'Callback', @startCallback);
        % Stop Button
        uicontrol('Style', 'pushbutton', ...
            'String', 'Stop', ...
            'Position', [140 50 100 30], ...
            'Callback', @stopCallback);
        % Status Text Box
        uicontrol('Style', 'text', ...
            'Tag', 'statusText',...  % Tag for easy access
            'String', 'Idle', ...
            'Position', [20 100 220 30], ...
            'FontSize', 12);
    end % end of create_gui
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
        handles.dataBuffer = zeros(0, 6); % Re-initialize dataBuffer at start as 0x6 matrix
        handles.byteBuffer = uint8([]);
        handles.isRunning = true;
        set(handles.statusText, 'String', 'Running... Press "P" to stop.');
        guidata(gcbo, handles); % Update handles
        data_acquisition_loop(); % Start data acquisition loop
    end % end of startCallback
    function stopCallback(~, ~)
        % Callback for the Stop button
        handles = guidata(gcbo);
        if handles.isRunning
            fprintf(handles.s, 'T'); % Send 'T' command to STM32 (optional)
            handles.isRunning = false;
            if isvalid(handles.statusText) % <---- CHECK if handles.statusText is still valid
                set(handles.statusText, 'String', 'Stopped by user.');
            else
                disp('Warning: statusText handle is invalid, cannot update status.'); % Debug message
            end
            guidata(gcbo, handles);
        else
            if isvalid(handles.statusText) % <---- CHECK if handles.statusText is still valid
                set(handles.statusText, 'String', 'Not running.');
            else
                disp('Warning: statusText handle is invalid, cannot update status.'); % Debug message
            end
        end
    end % end of stopCallback
    function keyPressCallback(~, event)
        % Callback for key presses on the figure
        handles = guidata(gcbo);
        if strcmp(event.Key, 'p') || strcmp(event.Key, 'P')
            stopCallback([], []); % Call stop function
        end
    end % end of keyPressCallback
    function closeGUI(~, ~)
        % Callback when GUI window is closed
        handles = guidata(gcbo);
        if handles.isRunning
            stopCallback([], []); % Stop data acquisition if running
        end
        if isvalid(fig) % <---- CHECK if the main figure 'fig' is still valid
            delete(fig); % Close the GUI window only if the figure is valid
        else
            disp('Warning: Figure handle is invalid, cannot delete.'); % Debug message
        end
    end % end of closeGUI
    function data_acquisition_loop()
        % Main data acquisition loop
        handles = guidata(gcbo); % Get handles at start of loop
        packet_count = 0;
        missed_header_count = 0;
        while handles.isRunning
            try
                if handles.s.NumBytesAvailable > 0
                    newBytes = read(handles.s, handles.s.NumBytesAvailable, 'uint8');
                    handles.byteBuffer = [handles.byteBuffer; newBytes(:)];
                end
                while numel(handles.byteBuffer) >= handles.packetSize
                    headerIdx = findHeader(handles.byteBuffer, handles.header);
                    if ~isempty(headerIdx)
                        if (numel(handles.byteBuffer) >= headerIdx + handles.packetSize - 1)
                            packet = handles.byteBuffer(headerIdx:headerIdx + handles.packetSize - 1);
                            handles.byteBuffer(1:headerIdx + handles.packetSize - 1) = [];
                            values = typecast(packet(9:end), 'uint32'); % Skip header and packet counter
                            packet_info = typecast(packet(5:end), 'uint32'); % Get packet counter value
                            packet_data = [packet_info(:); values(:)]; % Force both to be column vectors
                            % whos handles.dataBuffer packet_data' % Debug: Check dimensions
                            %handles.dataBuffer = [handles.dataBuffer; packet_data']; % Concatenate vertically
                            myDataBuffer = [myDataBuffer;packet_data'];
                            packet_count = packet_count + 1;
                        else
                            break; % Incomplete packet
                        end
                    else
                        missed_header_count = missed_header_count + 1;
                        if numel(handles.byteBuffer) > numel(handles.header)
                            handles.byteBuffer(1) = []; % Remove first byte
                        else
                            break; % Buffer too small
                        end
                        if missed_header_count > 1000
                            handles.isRunning = false;
                            set(handles.statusText, 'String', 'Too many header losses - stopped.');
                            guidata(gcbo, handles);
                            break;
                        end
                        break; % Search for header again
                    end
                end
                pause(0.0005); % Small delay
                handles = guidata(gcbo); % Get updated handles in each loop iteration (for stop command check)
            catch serial_error
                fprintf('Serial port error: %s\n', serial_error.message);
                set(handles.statusText, 'String', 'Serial port error.');
                handles.isRunning = false;
                guidata(gcbo, handles);
            end
        end
        % Loop finished (isRunning is false) - Cleanup and save
        if ~handles.isRunning && ~isempty(handles.s) && isvalid(handles.s) % Check if serial port is valid before clearing/closing
            clear handles.s;
        end
        % Save to "Data" directory
        directoryName = 'Data';
        if ~exist(directoryName, 'dir')
            mkdir(directoryName);
        end

        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
        filename = sprintf('%s/sensor_data_final_%s.mat', directoryName, timestamp);

        save(filename,'handles','packet_count', 'missed_header_count','packet_data',"myDataBuffer"); % Save inside "Data"

        disp(['Complete. Processed Packets: ', num2str(packet_count), ', Missed Headers: ', num2str(missed_header_count)]);

        set(handles.statusText, 'String', 'Data saved to sensor_data_final.mat.');
        guidata(gcbo, handles); % Update handles one last time before exit
    end % end of data_acquisition_loop
    function headerIdx = findHeader(buffer, header)
        % Helper function - Manual Byte Comparison - Optimized
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
    end % end of findHeader
end % end of main function usb_data_gui_final"