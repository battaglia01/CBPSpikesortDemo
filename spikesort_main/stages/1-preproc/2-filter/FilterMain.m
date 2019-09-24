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
    %%@ left-aligned to waveform start, rather than peak-aligned
    ir = filter(CBPdata.filtering.coeffs{1}, CBPdata.filtering.coeffs{2}, ...
                [1 zeros(1,100000)]);
    CBPdata.filtering.sampledelay = min(find(ir == max(ir)));

else
    fprintf('No filtering performed (params.filtering.freq was empty).\n');
    CBPdata.filtering.sampledelay = 0;
end

% Remove CHANNEL-WISE means
CBPdata.filtering.data = CBPdata.filtering.data ...
                         - repmat(mean(CBPdata.filtering.data, 2), 1, ...
                                  size(CBPdata.filtering.data, 2));

%%@ MIKE'S NOTE - Non-trivial and affects thresholds
% Scale GLOBALLY across all channels
dataMag = sqrt(sum(CBPdata.filtering.data.^2, 1)); %%@ RMS - RSS
CBPdata.filtering.data = CBPdata.filtering.data ./ max(dataMag);
