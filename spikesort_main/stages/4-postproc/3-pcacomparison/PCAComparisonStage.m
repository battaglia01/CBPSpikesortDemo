%% ----------------------------------------------------------------------------------
% Post-analysis: Comparison of CBP to clustering results, and to ground truth (if
% available)

%** indicate which cells match ground truth.

function PCAComparisonStage
global params dataobj;
UpdateStage(@PCAComparisonStage);

fprintf('***Postprocessing Step 4: PCA Comparison\n'); %%@New

%% ----------------------------------------------------------------------------------
% Visualize true spike assignments in PC-space

if isfield(dataobj.ground_truth, 'true_spike_class') && isfield(dataobj.ground_truth, 'true_spike_times')
    cluster_pars = params.clustering;
    if isempty(cluster_pars.window_len), cluster_pars.window_len = params.rawdata.waveform_len; end
    cluster_pars.align_mode = dataobj.rawdata.averaging_method;

    dataobj.ground_truth.Xstar = ConstructSnippetMatrix(dataobj.whitening.data, dataobj.ground_truth.true_spike_times, cluster_pars);
    % Remove mean component and project onto leading PC's
%    XProjstar = (Xstar - repmat(mean(Xstar, 2), 1, size(Xstar, 2)))' * PCs;
    dataobj.ground_truth.XProjstar=dataobj.ground_truth.Xstar'*dataobj.clustering.PCs;
    
    % Plot the putative spikes w.r.t. the 2 leading principal components.
    % PC's are computed across all (aligned) windows which pass the threshold
    % test. K-means clustering is performed using the PC's accounting for
    % cluster_pars.percent_variance portion of the total variance.
else
    fprintf('ERROR: No ground truth! Skipping postprocessing stage 4.\n'); %%@New
end

if (params.general.calibration_mode)
    PCAComparisonPlot;
end

% ADD NEW% Plot the putative spikes w.r.t. the 2 leading principal components.
% PC's are computed across all (aligned) windows which pass the threshold
% test. K-means clustering is performed using the PC's accounting for
% cluster_pars.percent_variance portion of the total variance.
% FIGURE OF HISTOGRAM OF WHITENED RMS SAMPLES cluster sthreshold
% ADD multiple PC plots (optional)

% What to check:
%
% 1. Adjust cluster_threshold to properly separate background activity from
%   spike data (shold cleanly separate histogram in Fig 200).
%
% 2. Adjust NUM_WAVEFORMS so that separate clusters in Fig 6 are identified
%    with separate colors (i.e. waveforms in Fig 7 should all have distinct
%    shapes).

fprintf('***Done postprocessing step 4!\n\n');
StageInstructions;
