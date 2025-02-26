function jumpIndices = detectJumps(data, threshold)
% ... (function documentation - explain input/output and purpose)
if length(data) <= 1
    jumpIndices = []; % No jumps possible
    return;
end
differences = diff(data);
jumpIndices = find(differences > threshold) + 1;
end