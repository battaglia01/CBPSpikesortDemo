% Find peaks (i.e. values greater than any other value within
% pars.peak_len samples).
function peak_idx = FindPeaks(data_L2_across_channels, threshold, pars)
if (size(data_L2_across_channels, 2) > 1)
    error('FindPeaks: can only find peaks in a vectorized signal!');
end
peak_idx = data_L2_across_channels > threshold;

% Don't include borders
peak_idx(1:pars.window_len) = false;
peak_idx(end-pars.window_len:end) = false;
for n=-pars.peak_len:pars.peak_len
    peak_idx = peak_idx & ...
               (data_L2_across_channels >= circshift(data_L2_across_channels, n));
end
peak_idx = find(peak_idx);
