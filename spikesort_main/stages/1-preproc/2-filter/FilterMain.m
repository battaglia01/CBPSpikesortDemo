%==========================================================================
% Preprocessing Step 2: Temporal filtering
%
% Remove low and high frequencies - purpose is to eliminate non-signal parts of the
% frequency spectrum, and enable crude removal of segments containing spikes via
% local amplitude thresholding, so that background noise covariance can be estimated.
% In addition to filtering, the code removes the mean from each channel, and rescales
% the data (globally) to have a max abs value of one.
% params.filtering includes:
%   - freq : range of frequencies (in Hz) for designing filter
%            Set to [] to turn off pre-filtering.
%   - type : type of filter for preprocessing. Currently supports
%            "fir1" and "butter"
%   - pad  : number of constant-value samples to pad
%   - order : order of the filter

function FilterMain
global CBPdata params CBPInternals;

% As starting point, copy all data from "rawdata" stage to "filtering"
CBPdata.filtering = CBPdata.rawdata;

% Now do filtering. Are filter frequencies specified?
if ~isempty(params.filtering.freq)
    % Pad with 0's
    paddata = PadTrace(CBPdata.filtering.data, params.filtering.pad);

    % Highpass/Bandpass filtering
    [CBPdata.filtering.data, CBPdata.filtering.coeffs] = ...
        FilterTrace(paddata, params.filtering, 1/(2*CBPdata.filtering.dt));

    % Remove padding
    CBPdata.filtering.data = ...
        CBPdata.filtering.data(:, ...
            (params.filtering.pad+1):(end-params.filtering.pad));

    % Set sample delay
    % get max value of impulse response. use that to set delay
    %%@ NOTE - still an issue if ground truth is offset, such as if it's
    %%@ left-aligned to waveform start, rather than peak-aligned.
    ir = filter(CBPdata.filtering.coeffs{1}, CBPdata.filtering.coeffs{2}, ...
                [1 zeros(1,100000)]);
    CBPdata.filtering.sampledelay = min(find(ir == max(ir)));

else
    fprintf('No filtering performed (params.filtering.freq was empty).\n');
    CBPdata.filtering.coeffs = {[1] [1]};
    CBPdata.filtering.sampledelay = 0;
end

% Remove CHANNEL-WISE means
CBPdata.filtering.data = CBPdata.filtering.data ...
                         - repmat(mean(CBPdata.filtering.data, 2), 1, ...
                                  size(CBPdata.filtering.data, 2));

%%@ MIKE'S NOTE - so the way this code was originally done, it normalizes
%%@ the filtering data so that the *max* L2-across-channels at all time
%%@ samples is equal to 1.
%%@
%%@ This can lead to strange results, though - if 
%%@ a 2-hr recording has ONE really huge spike, the entire thing will be
%%@ normalized relative to that! This makes for difficulty in setting
%%@ predictable "default" threshold levels for different data sets.
%%@
%%@ A better (or at least, "good-enough" way to do this would be to instead
%%@ normalize by the median absolute deviation of the flattened signal,
%%@ taken as a single vector. We can multiply the MAD by 1.4826 to get a
%%@ robust estimator for the noise std minus spikes. Then, we can we can
%%@ throw out all samples that are > a few estimated std's, and normalize
%%@ by the result.
%%@
%%@ Original code for reference:
% % Scale GLOBALLY across all channels
% data_L2_across_channels = sqrt(sum(CBPdata.filtering.data.^2, 1)); %%@ RMS vs L2?
% CBPdata.filtering.data = CBPdata.filtering.data ./ max(data_L2_across_channels);

%%@ New code:
mad_scl = 1.4826;   % scale factor to convert MAD to estimated STD
data_flat = CBPdata.filtering.data(:);

% the "1" in the second argument makes it the median
data_prelim_sig = mad_scl * mad(data_flat, 1);
data_no_outliers = data_flat(abs(data_flat) < 2*data_prelim_sig);
%%@ ^^ this is hard-coded to 2 sigs. could add param to make this variable

data_trimsig = mad_scl * mad(data_no_outliers);
CBPdata.filtering.data = CBPdata.filtering.data ./ data_trimsig;
