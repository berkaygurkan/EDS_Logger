function usb_data_gui_ds()
    % Create and run the USB Data Acquisition GUI
    % --- GUI Creation ---
    fig = create_gui();
    
    % --- GUI Components ---
    handles = guihandles(fig);
    handles.isRunning = false;
    handles.s = [];
    handles.dataBuffer = zeros(0, 6);  % 6 columns: packet_counter + 5 data values
    handles.byteBuffer = uint8([]);
    handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);  % Header bytes (little-endian)
    handles.packetSize = 28;  % 4 (header) + 4 (counter) + 20 (5x4 data)
    guidata(fig, handles);
    
    % --- Helper Functions ---
    function fig = create_gui()
        fig = figure('Name', 'USB Data Acquisition', ...
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
        
        % Status Text
        uicontrol('Style', 'text', ...
            'Tag', 'statusText', ...
            'String', 'Idle', ...
            'Position', [20 100 220 30], ...
            'FontSize', 12);
    end

    function startCallback(~, ~)
        handles = guidata(gcbo);
        if handles.isRunning
            set(handles.statusText, 'String', 'Already running.');
            return;
        end
        
        port = 'COM5';  % Replace with your COM port
        try
            handles.s = serialport(port, 115200);
            configureTerminator(handles.s, 'LF');  % Remove if STM32 doesn't send terminators
            fprintf(handles.s, 'S');  % Send start command
        catch e
            set(handles.statusText, 'String', ['Error: ', e.message]);
            return;
        end
        
        handles.dataBuffer = zeros(0, 6);  % Ensure 6 columns
        handles.byteBuffer = uint8([]);
        handles.isRunning = true;
        set(handles.statusText, 'String', 'Running... Press "P" to stop.');
        guidata(gcbo, handles);
        data_acquisition_loop();
    end

    function stopCallback(~, ~)
        handles = guidata(gcbo);
        if handles.isRunning
            fprintf(handles.s, 'T');  % Send stop command
            handles.isRunning = false;
            set(handles.statusText, 'String', 'Stopped by user.');
            guidata(gcbo, handles);
        end
    end

    function keyPressCallback(~, event)
        handles = guidata(gcbo);
        if strcmp(event.Key, 'p') || strcmp(event.Key, 'P')
            stopCallback([], []);
        end
    end

    function closeGUI(~, ~)
        handles = guidata(gcbo);
        if handles.isRunning, stopCallback([], []); end
        delete(fig);
    end

    function data_acquisition_loop()
        handles = guidata(gcbo);
        packet_count = 0;
        missed_header_count = 0;
        
        while handles.isRunning
            try
                % Read all available bytes
                if handles.s.NumBytesAvailable > 0
                    newBytes = read(handles.s, handles.s.NumBytesAvailable, 'uint8');
                    handles.byteBuffer = [handles.byteBuffer; newBytes(:)];
                end
                
                % Process packets
                while numel(handles.byteBuffer) >= handles.packetSize
                    headerIdx = findHeader(handles.byteBuffer, handles.header);
                    if isempty(headerIdx)
                        % Remove first byte if header not found
                        handles.byteBuffer(1) = [];
                        missed_header_count = missed_header_count + 1;
                        if missed_header_count > 1000
                            error('Too many header losses.');
                        end
                        continue;
                    end
                    
                    % Extract packet
                    packetStart = headerIdx;
                    packetEnd = headerIdx + handles.packetSize - 1;
                    if numel(handles.byteBuffer) < packetEnd
                        break;  % Incomplete packet
                    end
                    
                    packet = handles.byteBuffer(packetStart:packetEnd);
                    handles.byteBuffer(1:packetEnd) = [];  % Remove processed bytes
                    
                    % Parse packet
                    packet_counter = typecast(packet(5:8), 'uint32');  % Bytes 5-8: counter
                    data_values = typecast(packet(9:28), 'uint32');    % Bytes 9-28: 5 data values
                    
                    % Append to buffer
                    handles.dataBuffer = [handles.dataBuffer; [packet_counter, data_values']];
                    packet_count = packet_count + 1;
                end
                
                pause(0.001);
                handles = guidata(gcbo);
                guidata(gcbo, handles);  % Update handles
                
            catch e
                fprintf('Error: %s\n', e.message);
                handles.isRunning = false;
                set(handles.statusText, 'String', 'Error occurred.');
                guidata(gcbo, handles);
                break;
            end
        end
        
        % Cleanup
        if ~isempty(handles.s) && isvalid(handles.s)
            clear handles.s;
        end
        save('sensor_data.mat', 'handles');
        disp(['Processed Packets: ', num2str(packet_count)]);
        set(handles.statusText, 'String', 'Data saved.');
        guidata(gcbo, handles);
    end

    function headerIdx = findHeader(buffer, header)
        % Vectorized header search (fast)
        headerLen = numel(header);
        bufferLen = numel(buffer);
        if bufferLen < headerLen
            headerIdx = [];
            return;
        end
        % Compare all possible segments to the header
        idx = 1:(bufferLen - headerLen + 1);
        matches = arrayfun(@(i) all(buffer(i:i+headerLen-1) == header), idx);
        headerIdx = find(matches, 1);
    end
end