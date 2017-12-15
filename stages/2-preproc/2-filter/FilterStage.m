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
%
% Calibration for filtering:
%   Fig 1b shows filtered data.  In the next step, noise covariance will be estimated
%   from below-threshold regions, which are indicated in red. There should be no spikes
%   in these regions.  Fig 2 shows Fourier amplitude (effects of filtering should be
%   visible).  Fig 3 shows histogram of the cross-channel magnitudes.  Below-threshold
%   portion is colored red, and should look like a chi distribution with fitted
%   variance (green curve).  If spikes appear to be included in the noise segments,
%   reduce params.whitening.noise_threshold before proceeding, or modify the filtering
%   parameters in params.filtering, and re-run the filtering step.

function FilterStage
global params dataobj;

fprintf('***Preprocessing Step 2: Temporal filtering\n'); %%@New

dataobj.filtering = FilterData(dataobj.rawdata);

if (params.general.calibration_mode)
    PlotFilteredData(dataobj.filtering);
end

fprintf('***Done preprocessing step 2.');
CBPNext('WhitenStage');
