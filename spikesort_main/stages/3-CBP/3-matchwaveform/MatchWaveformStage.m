<<<<<<< HEAD
%% ----------------------------------------------------------------------------------
% CBP step 3: Identify spikes by thresholding amplitudes of each cell
%
% Fig7 allows interactive adjustment of waveform amplitudes, while visualizing effect
% on spike train auto- and cross-correlations.  Top row shows amplitude distribution
% (typical spikes should have amplitude 1), with expected (Gaussian) noise
% distribution at left, and thresholds indicated by vertical lines.  Threshold lines
% can be mouse-dragged right or left.  Next row shows spike train autocorrelation
% that would result from chosen threshold, and can be examined for refractory
% violations.  Bottom rows show spike train cross-correlations across pairs of cells,
% and can be examined for dropped synchronous spikes (very common with clustering
% methods).  Click the "Use thresholds" button to proceed with the chosen values.
% Click the "Revert" button to revert to the automatically-chosen default values.

function MatchWaveformStage
global params dataobj;

fprintf('***CBP step 3: Identify spikes by thresholding amplitudes of each cell\n'); %%@New
CBPinfo = dataobj.CBPinfo;

% Calculate default thresholds.  This is done by fitting the amplitude
% distribution (using a Gaussian kernel density estimator) and then choosing the
% largest local minimum.
CBPinfo.amp_thresholds = cellfun(@(sa) ComputeKDEThreshold(sa, params.amplitude), CBPinfo.spike_amps);

% Visualize thresholds (only works if image processing toolbox is installed).
if (params.general.calibration_mode)
    AmplitudeThresholdGUI(CBPinfo.spike_amps, CBPinfo.spike_times, ...
                          CBPinfo.amp_thresholds, ...
                          'dt', dataobj.whitening.dt, ...
                          'wfnorms', cellfun(@(wf) norm(wf), ...
                          dataobj.clustering.init_waveforms), ...
                          'location_slack', params.postproc.spike_location_slack);
end

dataobj.CBPinfo = CBPinfo;
fprintf('***Done CBP step 3.\n\n');
CBPNext('WaveformReestimationStage');
=======
%% ----------------------------------------------------------------------------------
% CBP step 3: Identify spikes by thresholding amplitudes of each cell
%
% Fig7 allows interactive adjustment of waveform amplitudes, while visualizing effect
% on spike train auto- and cross-correlations.  Top row shows amplitude distribution
% (typical spikes should have amplitude 1), with expected (Gaussian) noise
% distribution at left, and thresholds indicated by vertical lines.  Threshold lines
% can be mouse-dragged right or left.  Next row shows spike train autocorrelation
% that would result from chosen threshold, and can be examined for refractory
% violations.  Bottom rows show spike train cross-correlations across pairs of cells,
% and can be examined for dropped synchronous spikes (very common with clustering
% methods).  Click the "Use thresholds" button to proceed with the chosen values.
% Click the "Revert" button to revert to the automatically-chosen default values.

function MatchWaveformStage
global params dataobj;

fprintf('***CBP step 3: Identify spikes by thresholding amplitudes of each cell\n'); %%@New
CBPinfo = dataobj.CBPinfo;

% Calculate default thresholds.  This is done by fitting the amplitude
% distribution (using a Gaussian kernel density estimator) and then choosing the
% largest local minimum.
CBPinfo.amp_thresholds = cellfun(@(sa) ComputeKDEThreshold(sa, params.amplitude), CBPinfo.spike_amps);

% Visualize thresholds (only works if image processing toolbox is installed).
if (params.general.calibration_mode)
    AmplitudeThresholdGUI(CBPinfo.spike_amps, CBPinfo.spike_times, ...
                          CBPinfo.amp_thresholds, ...
                          'dt', dataobj.whitening.dt, ...
                          'wfnorms', cellfun(@(wf) norm(wf), ...
                          dataobj.clustering.init_waveforms), ...
                          'location_slack', params.postproc.spike_location_slack);
end

dataobj.CBPinfo = CBPinfo;
fprintf('***Done CBP step 3.\n\n');
CBPNext('WaveformReestimationStage');
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
