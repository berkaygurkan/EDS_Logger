function store_usb_data_binary()

% Configure serial port
port = 'COM5'; % Replace with your port
s = serialport(port, 115200);
configureTerminator(s, 'LF'); % Not used in binary mode, but required for MATLAB

% Add key press listener to stop on 'P'
fig = figure;
set(fig, 'KeyPressFcn', @(src, event) stopOnKeyPress(event));
isRunning = true; % Stop the loop
% Initialize variables
dataBuffer = []; % Store parsed data
byteBuffer = []; % Accumulate raw bytes
header = [0xAA, 0xBB, 0xCC, 0xDD]; % Header to identify packets
packetSize = 24; % Header (4 bytes) + 5 uint32_t values (20 bytes)

timeout = 5; % Maximum time to wait (seconds)
startTime = tic();
% Start reading data
disp('Reading data. Press "P" to stop...');

cnt = 0;

while isRunning
    while s.NumBytesAvailable == 0 && toc(startTime) < timeout
        pause(0.01);  % Check every 10ms
    end

    if s.NumBytesAvailable > 0
        newBytes = read(s, s.NumBytesAvailable, 'uint8');
        byteBuffer = [byteBuffer; newBytes'];

        % Process complete packets
        while numel(byteBuffer) >= packetSize
            % Find the header
            headerIdx = find(byteBuffer(1:end-3) == header(1) & ...
                byteBuffer(2:end-2) == header(2) & ...
                byteBuffer(3:end-1) == header(3) & ...
                byteBuffer(4:end) == header(4), 1);

            if isempty(headerIdx)
                % No header found, discard bytes
                byteBuffer = [];
                break;
            end

            % Extract the packet
            if numel(byteBuffer) >= headerIdx + packetSize - 1
                packet = byteBuffer(headerIdx:headerIdx + packetSize - 1);
                byteBuffer(1:headerIdx + packetSize - 1) = []; % Remove processed bytes

                % Parse the packet (skip header)
                packet=uint8(packet);
                %%values = typecast(packet(5:end), 'uint32'); % Convert to uint32
                values = swapbytes(typecast(uint8(packet(5:end)), 'uint32'));
                dataBuffer = [dataBuffer; values']; % Append to data buffer
                cnt=cnt+1;
            else
                % Incomplete packet, wait for more data
                break;
            end
        end
    end
    if cnt>5000
        isRunning = false;
    end
end

% Cleanup
clear s;
save('binary_data.mat', 'dataBuffer');
disp('Data saved to binary_data.mat.');

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