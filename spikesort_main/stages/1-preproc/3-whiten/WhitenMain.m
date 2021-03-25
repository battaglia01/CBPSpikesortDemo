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
% FIXME?: Appears to clip raw_data
%%@ (Mike's note - old FIXME, may be better now)

function WhitenMain
global CBPdata params CBPInternals;

% As starting point, copy all data from "filtering" stage to "whitening"
CBPdata.whitening = CBPdata.filtering;

% Now preprocess extracellularly recorded voltage trace by estimating noise
% and whitening if desired.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Noise zone estimation

% Merge channels into one by taking pointwise RMS of data
%%@ (should really allow a more general p-norm...)
data_L2_across_channels = sqrt(sum(CBPdata.filtering.data .^ 2, 1));  %%@ RMS vs L2?

% Estimate noise zones
min_zone_len = params.whitening.min_zone_len;

%%@ Mike's addition - assume these thresholds are given in "Linf-equivalent"
%%@ units. Convert to L2
nchan = size(CBPdata.filtering.data, 1);
thresh = params.whitening.noise_threshold;
L2_equivalent_thresh = ConvertLinfThresholdToL2(thresh, nchan);
noise_zone_idx = GetNoiseZones(data_L2_across_channels, ...
                               L2_equivalent_thresh, ...
                               min_zone_len);

% Test if noise covariance matrix is singular
if(isempty(noise_zone_idx))
    error("WHITENING ERROR: No noise zones found! This often happens if the threshold is set too high.\n" + ...
          "Increase params.whitening.noise_threshold and try again!", "");
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Whiten trace if desired
[CBPdata.whitening.data, CBPdata.whitening.old_acfs, ...
 CBPdata.whitening.whitened_acfs, CBPdata.whitening.old_cov, ...
 CBPdata.whitening.whitened_cov] = ...
    WhitenTrace(CBPdata.filtering.data', ...
                noise_zone_idx, ...
                params.whitening.num_acf_lags, ...
                params.whitening.reg_const);

CBPdata.whitening.noise_sigma = 1;
CBPdata.whitening.noise_zone_idx = noise_zone_idx;
