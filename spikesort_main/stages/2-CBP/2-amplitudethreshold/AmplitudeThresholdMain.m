%% ----------------------------------------------------------------------------------
% CBP step 2: Identify spikes by thresholding amplitudes of each cell

function AmplitudeThresholdMain
global CBPdata params CBPInternals;

% Calculate default thresholds.  This is done by fitting the amplitude
% distribution (using a Gaussian kernel density estimator) and then choosing the
% largest local minimum.

num_points = params.amplitude.kdepoints;
range = params.amplitude.kderange;
peak_width = params.amplitude.kdewidth;

CBPdata.amplitude.true_sp = {}; % not implemented yet

CBPdata.amplitude.amp_thresholds = ...
    cellfun(@(sa) ComputeKDEThreshold(sa, num_points, range, peak_width), ...
            CBPdata.CBP.spike_amps);
