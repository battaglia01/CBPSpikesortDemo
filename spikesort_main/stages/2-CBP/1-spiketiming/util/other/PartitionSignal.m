function [snippets, breaks, snippet_lens, snippet_centers, IDX] = ...
    PartitionSignal(signal, pars)
%
% Splits a signal into multiple "snippets" containing significant activity.
% Also returns "dead zones" from between the snippets.
%
% Arguments
%
% signal : channel x time matrix (input)
%
% pars : struct with fields:
%   silence_threshold : threshold to use on the root-mean-squared value of signal
%               (across channels) to be considered activity
%               (should be noise-dependent)
%
%   smooth_len : length of moving average to smooth the signal RMS before
%                thresholding.
%
%   min_silence_len : minimum width (in samples) required to be considered a
%                       dead zone (should depend on autocorrelation width of
%                       waveform)
%
%   min_snippet_len : minimum allowable length for a training segment
%                     (pad with zeros to satisfy the minimum length
%                     requirement)
%
%   max_snippet_len : maximum allowable length for a training segment
%
%   min_pad_size : minimum number to pad on EACH side of each snippet.
%
%
% Returns:
%   snippets     : cell array of snippets of signals
%   breaks       : cell array of spaces between snippets
%   snippet_lens : vector of snippet lengths
%
% Dependencies:
%   ImageProcessingToolbox:
%       BWCONNCOMP
%
% FIXME?: Return centers, lens of breaks as well...
%%@ ^ MIKE'S NOTE - do we need this?


% Take a moving average
% NOTE: transpose makes this a row vector again
%%@ Mike's note: this "rms" was originally a sum instead of a mean. I changed it
%%@ to a root-mean-squared to make everything cleaner.
% signal_rms = smooth(sqrt(sum(signal.^2, 1)), pars.smooth_len)'; - % old
%%@ Also, for various reasons, it is easier if we do the smoothing before the
%%@ sqrt. Then we are simply taking an RMS of N (presumably Gaussian) samples,
%%@ and can easily convert between Linf and RMS-based thresholds
signal_rms = sqrt(smooth(mean(signal.^2, 1), pars.smooth_len))';    %%@ RMS vs L2?

% Identify dead zones
%%@ Mike's note: the following was originally left commented as a reference.
%%@ just leaving it here
%dof = size(signal,1);
%chiMean = sqrt(2)*gamma((dof+1)/2)/gamma(dof/2);
%chiVR = dof - chiMean^2;
%rms_above_thresh = signal_rms > (chiMean + pars.silence_threshold*sqrt(chiVR));

%%@ Mike's note: originally, we had the following line of code:
%%@    rms_above_thresh = signal_rms > pars.silence_threshold*std(signal_rms);
%%@ where the "signal_rms" was, as mentioned above, a "root-sum-squared" rather
%%@ than a root-mean-squared.
%%@ This does cancel out that "signal_rms" was originally a "root-sum-squared"
%%@ rather than a "root-mean squared," since we divide by std(signal_rms).
%%@ However, it s a strange choice of "units" for the threshold - as a percentage of
%%@ the std of signal_rms. Assuming a Gaussian signal, then we have that
%%@ signal_rms is chi-distributed, so it is strange to set the threshold as a
%%@ percentage of the standard deviation of this chi distribution (which will
%%@ be some strange expression involving the gamma function).
%%@ Instead, let's make it so that thresholds are expressed as an expected *max*
%%@ or *Linf* value, for compatibility with different spike sorters, and then
%%@ just scale that to make it an expected rms threshold. We are taking an RMS
%%@ of the current sample at each channel, and then an "rms-smoothing" of
%%@ pars.smooth_len consecutive samples, so the total number of samples we
%%@ are rms'ing is the product of pars.smooth_len * size(signal,1).
rms_above_thresh = signal_rms > ...
        ConvertLinfThresholdToRMS(pars.silence_threshold, ...
                                  pars.smooth_len * size(signal,1));

dead_zone_idx = FindConsecutiveZeroes(rms_above_thresh, pars.min_silence_len);


% Find the "islands of 1's" in dead_zone_idx
IDX = bwconncomp(~dead_zone_idx);
num_snippets = IDX.NumObjects;
IDX = IDX.PixelIdxList;


% Make a cell array of snippets

snippets = cell(num_snippets, 1);

snippet_lens = zeros(num_snippets, 1);
snippet_centers = zeros(size(snippet_lens));

for i = 1 : num_snippets
    idx = IDX{i};
    if (length(idx) > pars.max_snippet_len)
        error("While pre-partitioning the signal into 'snippets', found " + ...
              "a contiguous snippet whose length %d exceeds the maximum (%d)!\n" + ...
              "This is often because params.partition.silence_threshold is "+ ...
              "set too low.\n\n" + ...
              "Try increasing params.partition.silence_threshold and try again!\n\n" + ...
              "Or, the maximum can be changed at params.partition.max_snippet_len.", ...
              length(idx), pars.max_snippet_len);
    end

    % If the snippet is too small, widen the borders by appropriate size
    pad_size = max(pars.min_pad_size, ...
        ceil((pars.min_snippet_len - length(idx)) / 2));
    lhs_pad_idx = max(1, idx(1) - pad_size) : (idx(1) - 1);
    rhs_pad_idx = (idx(end) + 1) : ...
                  min(size(signal, 2), idx(end) + pad_size);

    idx = [lhs_pad_idx(:); idx(:); rhs_pad_idx(:)];
    if (mod(length(idx), 2) == 0)
        if (idx(end) == size(signal, 2))
            idx = [idx(1) - 1; idx];
        else
            idx = [idx; idx(end) + 1];
        end
    end

    % add error condition that all indices are positive
    idx(idx<1) = [];

    % Store the indices of the snippet in IDX.
    IDX{i} = idx;

    snippets{i} = signal(:, idx)';
    snippet_lens(i) = size(snippets{i}, 1);
    snippet_centers(i) = round(median(idx)); % snippet center
end


% Save out breaks between snippets as well
deadzoneidx = true(1, size(signal,2));
deadzoneidx(cell2mat(IDX')) = false;
breaks_idx = bwconncomp(deadzoneidx);
breaks_idx = breaks_idx.PixelIdxList;
breaks = cellfun(@(i) signal(:,i)', breaks_idx, 'UniformOutput', false);

fprintf('Partitioned signal into %d snippets\n', length(snippets));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function block_idx = FindConsecutiveZeroes(logical_vec, min_block_len)
% Given a logical vector, find regions of at least min_block_len
% consecutive 0's. Return a logical vector indexing only these blocked
% regions.

vec = double(logical_vec(:));
if (vec(1) ~= 0)
    fprintf('input vector must start with 0!');
    fprintf('WARNING: setting it to 0 anyway.\n');
    vec(1) = 0;
end

% Find indices at which logical_vec switches from 0 to 1.
% Assume an up cannot happen at the first index.
up_idx = find(vec(2 : end) - vec(1 : end - 1) == 1)+ 1;
% "" "" 1 to 0
% Assume an down cannot happen at the last index
down_idx = [1; find(vec(1 : end - 1) - vec(2 : end) == 1)];

% Add an "up" at Infinity if needed
if (length(down_idx) == length(up_idx) + 1)
    up_idx = [up_idx; Inf];
end

% Sort ups and downs - they MUST alternate.
% A down at 1 is always the first event.
if (length(up_idx) ~= length(down_idx))
    error('Number of ups (%d) does not equal number of downs (%d)', ...
        length(up_idx), length(down_idx));
end
valid_change_idx = find(up_idx - down_idx > min_block_len);
block_idx = false(size(logical_vec));
num_changes = length(valid_change_idx);
% fprintf('Found %d regions\n', num_changes);

for change_num = 1 : num_changes
    lhs_idx = down_idx(valid_change_idx(change_num)) + 1;
    rhs_idx = up_idx(valid_change_idx(change_num)) - 1;
    block_idx(lhs_idx : min(length(vec), rhs_idx)) = true;
end
