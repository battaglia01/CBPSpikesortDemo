% Pad with constant values on left/right side to avoid border effects from
% filtering
function raw_data = PadTrace(raw_data, npad)
    raw_data = padarray(raw_data, [0 npad], 0, 'both');
    raw_data(:, 1 : npad) = repmat(raw_data(:, npad + 1), 1, npad);
    raw_data(:, end - npad + 1 : end) = ...
        repmat(raw_data(:, end - npad), 1, npad);
end
