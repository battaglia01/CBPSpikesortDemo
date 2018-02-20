%==========================================================================
% Preprocessing Step 3: Estimate noise covariance and whiten data
%
% Estimate and whiten the noise, assuming channel/time separability. This makes the
% L2-norm portion of the CBP objective into a sum of squares, simplifying the
% computation and improving computational efficiency.
% The algorithm, essentially, is:
%   - find "noise zones"
%   - compute noise auto-correlation function from these zones
%   - whiten each channel in time with the inverse matrix sqrt of the auto-correlation
%   - whiten across channels with inverse matrix sqrt of the covariance matrix.
% params.whitening includes:
%   - noise_threshold: noise zones must have cross-channel L2-norm less than this.
%   - min_zone_len: noise zones must have duration of at least this many samples.
%   - num_acf_lags: number of samples over which auto-correlation is estimated.
%
% Calibration for whitening:
% Fig 4: original vs. whitened autocorrelation(s), should be close to a delta
%   function (1 at 0, 0 elsewhere).  If not, try increasing
%   params.whitening.num_acf_lags.  If auto-correlation is noisy, there may not be
%   enough data samples for estimation.  This can be improved by a. increasing
%   params.whitening.noise_threshold (allow more samples) b. decreasing
%   params.whitening.num_acf_lags c. decreasing params.whitening.min_zone_len (allow
%   shorter noise zones).
% Fig 5 (multi-electrodes only): cross-channel correlation, should look like the
%   identity matrix. If not, a. increase params.whitening.num_acf_lags or b. increase
%   params.whitening.min_zone_len .  Note that this trades off with the quality of
%   the estimates (see prev).
% Fig 1: Highlighted segments of whitened data (green) will be used to estimate
%   waveforms in the next step.  These should contain spikes (and non-highlighted
%   regions should contain background noise).  Don't worry about getting all the
%   spikes: these are only used to initialize the waveforms!
% Fig 3, Top: Histograms of whitened channels - central portion should look
%   Gaussian. Bottom: Histogram of across-channel magnitude, with magnitudes of
%   highlighted segments in green.  If lots of spikes are in noise regions, reduce
%   params.whitening.noise_threshold

function WhitenStage
global params dataobj;
UpdateStage(@WhitenStage);

fprintf('***Preprocessing Step 3: Estimate noise covariance and whiten data\n');

dataobj.whitening = WhitenNoise(dataobj.filtering);

if (params.general.calibration_mode)
    WhitenPlot;
end

parout = params;

fprintf('***Done preprocessing step 3.\n\n');
StageInstructions;