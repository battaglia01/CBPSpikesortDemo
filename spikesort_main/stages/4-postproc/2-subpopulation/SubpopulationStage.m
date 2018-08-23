%% ----------------------------------------------------------------------------------
% Post-analysis: Comparison of CBP to clustering results, and to ground truth (if
% available)

%** indicate which cells match ground truth.

function SubpopulationStage
global params dataobj;
UpdateStage(@SubpopulationStage);

fprintf('***Postprocessing Step 3: Subpopulations\n'); %%@New

%% ----------------------------------------------------------------------------------
% Post-analysis: Comparison of CBP to clustering results, and to ground truth (if
% available)

%** indicate which cells match ground truth.

dataobj.ground_truth = load(dataobj.filename, 'true_spike_times', 'true_spike_class', 'dt');
dataobj.ground_truth.filename = dataobj.filename;

if isfield(dataobj.ground_truth, 'true_spike_times') && isfield(dataobj.ground_truth, 'true_spike_class')
    % Reformat as 1-cellarr per cell of spike times.
    dataobj.ground_truth.true_sp = GetSpikeTimesFromAssignments(dataobj.ground_truth.true_spike_times, dataobj.ground_truth.true_spike_class);

    % Reorder to match cell numbering from clustering.
    [dataobj.ground_truth.true_sp, ...
     dataobj.ground_truth.true_spike_times, ...
     dataobj.ground_truth.true_spike_class] = ReorderCells( ...
        dataobj.ground_truth.true_sp, dataobj.clustering.spike_times_cl, params.postproc.spike_location_slack);

  % Since we already permuted ground truth to match clustering, this is true by definition
  best_ordering_cl = 1:length(dataobj.clustering.spike_times_cl);
  best_ordering = 1:length(dataobj.CBPinfo.spike_times);

  % Evaluate clustering sorting
  [total_misses_cl, total_false_positives_cl, misses_cl, false_positives_cl] = ...
      evaluate_sorting(dataobj.clustering.spike_times_cl, dataobj.ground_truth.true_sp, params.postproc.spike_location_slack);
  fprintf('Clustering: %s', SortingEvaluationStr(dataobj.ground_truth.true_sp, dataobj.clustering.spike_times_cl, total_misses_cl, total_false_positives_cl));

  % Evaluate CBP sorting
  [total_misses, total_false_positives, prune_est_times, misses, false_positives] = ...
     EvaluateSorting(dataobj.CBPinfo.spike_times, dataobj.CBPinfo.spike_amps, dataobj.ground_truth.true_sp, 'threshold', dataobj.CBPinfo.amp_thresholds, 'location_slack', params.postproc.spike_location_slack);
  fprintf('       CBP: %s', SortingEvaluationStr(dataobj.ground_truth.true_sp, prune_est_times, total_misses, total_false_positives));

end

%% ----------------------------------------------------------------------------------
% Plot various snippet subpopulations

if (params.general.calibration_mode)
    SubpopulationPlot;
end

fprintf('***Done postprocessing step 3!\n\n');
StageInstructions;

%% ----------------------------------------------------------------------------------
% Quick addendum about ground truth

if ~isfield(dataobj.ground_truth,'true_spike_times') || ~isfield(dataobj.ground_truth,'true_spike_class')
    disp([10 'NOTE - file does not contain all ground truth information.'])
    disp(['Some of the next stages require ground truth; these will be skipped.' 10])
end