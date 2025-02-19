function usb_data_gui()
    % Create and run the USB Data Acquisition GUI
    % --- GUI Creation ---
    fig = create_gui();
    % --- GUI Components ---
    handles = guihandles(fig); 
    handles.isRunning = false;
    handles.s = [];
    handles.dataBuffer = zeros(0, 6); % 6 columns: packet counter + 5 data values
    handles.byteBuffer = uint8([]);
    handles.header = uint8([0xAA, 0xBB, 0xCC, 0xDD]);
    handles.packetSize = 28; 
    guidata(fig, handles); 

    % --- Nested Helper Functions ---
    function fig = create_gui()
        fig = figure('Name', 'USB Data Acquisition Final', ...
            'NumberTitle', 'off', ...
            'KeyPressFcn', @keyPressCallback, ...
            'CloseRequestFcn', @closeGUI);
        
        % Start/Stop Buttons
        uicontrol('Style', 'pushbutton', 'String', 'Start', ...
            'Position', [20 50 100 30], 'Callback', @startCallback);
        uicontrol('Style', 'pushbutton', 'String', 'Stop', ...
            'Position', [140 50 100 30], 'Callback', @stopCallback);
        
        % Status Text
        uicontrol('Style', 'text', 'Tag', 'statusText', ...
            'String', 'Idle', 'Position', [20 100 220 30], 'FontSize', 12);
        
        % Plot Axes
        ax = axes('Parent', fig, 'Position', [0.1 0.2 0.8 0.7], 'Tag', 'dataAxes');
        hold(ax, 'on');
        colors = lines(5); % Colors for 5 data channels
        for i = 1:5
            line('XData', [], 'YData', [], 'Color', colors(i,:), ...
                'Parent', ax, 'Tag', ['line' num2str(i)]);
        end
        hold(ax, 'off');
        xlabel(ax, 'Packet Counter');
        ylabel(ax, 'Value');
        title(ax, 'Real-time Data');
        legend(ax, {'Data1', 'Data2', 'Data3', 'Data4', 'Data5'});
    end

    function startCallback(~, ~)
        handles = guidata(gcbo);
        if handles.isRunning
            set(handles.statusText, 'String', 'Already running.');
            return;
        end
        port = 'COM5'; 
        try
            handles.s = serialport(port, 115200);
            configureTerminator(handles.s, 'LF');
            fprintf(handles.s, 'S'); 
        catch e
            set(handles.statusText, 'String', ['Error: ', e.message]);
            return;
        end
        handles.dataBuffer = zeros(0, 6); 
        handles.byteBuffer = uint8([]);
        handles.isRunning = true;
        set(handles.statusText, 'String', 'Running... Press "P" to stop.');
        guidata(gcbo, handles);
        data_acquisition_loop(); 
    end

    function stopCallback(~, ~)
        handles = guidata(gcbo);
        if handles.isRunning
            fprintf(handles.s, 'T'); 
            handles.isRunning = false;
            set(handles.statusText, 'String', 'Stopped.');
            guidata(gcbo, handles);
        end
    end

    function keyPressCallback(~, event)
        if strcmp(event.Key, 'p') || strcmp(event.Key, 'P')
            stopCallback([], []); 
        end
    end

    function closeGUI(~, ~)
        handles = guidata(gcbo);
        if handles.isRunning
            stopCallback([], []); 
        end
        delete(fig); 
    end

    function data_acquisition_loop()
        handles = guidata(gcbo);
        packet_count = 0;
        missed_header_count = 0;
        lastPlotUpdate = tic; 
        
        while handles.isRunning
            try
                if handles.s.NumBytesAvailable > 0
                    newBytes = read(handles.s, handles.s.NumBytesAvailable, 'uint8');
                    handles.byteBuffer = [handles.byteBuffer; newBytes(:)];
                end
                
                while numel(handles.byteBuffer) >= handles.packetSize
                    headerIdx = findHeader(handles.byteBuffer, handles.header);
                    if ~isempty(headerIdx)
                        if (numel(handles.byteBuffer) >= headerIdx + handles.packetSize - 1
                            packet = handles.byteBuffer(headerIdx:headerIdx + handles.packetSize - 1);
                            handles.byteBuffer(1:headerIdx + handles.packetSize - 1) = [];
                            
                            % Parse packet
                            packet_counter = typecast(packet(5:8), 'uint32');
                            data_values = typecast(packet(9:end), 'uint32');
                            new_row = [packet_counter; data_values]';
                            handles.dataBuffer = [handles.dataBuffer; new_row];
                            packet_count = packet_count + 1;
                            
                            % Update plot every 0.1 seconds
                            if toc(lastPlotUpdate) >= 0.1
                                update_plot(handles.dataBuffer);
                                lastPlotUpdate = tic;
                            end
                        end
                    else
                        missed_header_count = missed_header_count + 1;
                        if numel(handles.byteBuffer) > numel(handles.header)
                            handles.byteBuffer(1) = [];
                        end
                    end
                end
                pause(0.0005);
                handles = guidata(gcbo);
                guidata(fig, handles); 
            catch e
                fprintf('Error: %s\n', e.message);
                set(handles.statusText, 'String', 'Error occurred.');
                handles.isRunning = false;
                guidata(gcbo, handles);
            end
        end
        
        % Cleanup and save
        if ~isempty(handles.s) && isvalid(handles.s)
            clear handles.s;
        end
        save('sensor_data_final.mat', 'handles', 'packet_count', 'missed_header_count');
        set(handles.statusText, 'String', 'Data saved.');
        guidata(gcbo, handles);
    end

    function update_plot(data)
        ax = findobj(fig, 'Tag', 'dataAxes');
        if ~isempty(data)
            xData = data(:,1);
            for i = 1:5
                line = findobj(ax, 'Tag', ['line' num2str(i)]);
                set(line, 'XData', xData, 'YData', data(:,i+1));
            end
            % Adjust x-axis to show latest 100 points
            if length(xData) > 100
                xlim(ax, [xData(end-100), xData(end)]);
            else
                xlim(ax, [xData(1), xData(end)]);
            end
            drawnow limitrate;
        end
    end

    function headerIdx = findHeader(buffer, header)
        headerLen = length(header);
        for idx = 1:length(buffer)-headerLen+1
            if isequal(buffer(idx:idx+headerLen-1), header)
                headerIdx = idx;
                return;
            end
        end
        headerIdx = [];
    end
end