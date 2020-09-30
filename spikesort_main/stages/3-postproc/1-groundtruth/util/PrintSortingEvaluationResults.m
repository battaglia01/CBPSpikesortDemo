% This function is a simple script that prints the results of how well the
% current sorting permutation assignment labels match those of ground
% truth.
function PrintSortingEvaluationResults
global CBPdata params CBPInternals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print the current sorting permutation for Clustering
fprintf('\n');
fprintf('*** CLUSTERING RESULTS ***\n');
fprintf('Best labeling permutation:\n');
fprintf('(nth entry is the estimated waveform assignment for ground truth waveform ID #n)\n');
fprintf(['    [' num2str(CBPdata.groundtruth.best_ordering_cl) ']\n\n']);

% Then print the error matrices
fprintf('False negative assignment matrix:\n');
disp(CBPdata.groundtruth.miss_mtx_cl);
fprintf('False positive assignment matrix:\n');
disp(CBPdata.groundtruth.fp_mtx_cl);
fprintf('Total error assignment matrix:\n');
disp(CBPdata.groundtruth.all_err_mtx_cl);
fprintf('\n');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print the current sorting permutation for CBP
fprintf('\n');
fprintf('*** CBP RESULTS ***\n');
fprintf('Best labeling permutation:\n');
fprintf('(nth entry is the estimated waveform assignment for ground truth waveform ID #n)\n');
fprintf(['    [' num2str(CBPdata.groundtruth.best_ordering_cbp) ']\n\n']);

% Then print the error matrices
fprintf('False negative assignment matrix:\n');
disp(CBPdata.groundtruth.miss_mtx_cbp);
fprintf('False positive assignment matrix:\n');
disp(CBPdata.groundtruth.fp_mtx_cbp);
fprintf('Total error assignment matrix:\n');
disp(CBPdata.groundtruth.all_err_mtx_cbp);
fprintf('\n');

% and lastly, evaluate results
[total_misses_cl, total_false_positives_cl, misses_cl, ...
 false_positives_cl] = EvaluateSortingLowLevel( ...
        CBPdata.clustering.spike_time_array_cl, ...
        CBPdata.groundtruth.spike_time_array_processed, ...
        params.amplitude.spike_location_slack);
fprintf('Clustering: %s', SortingEvaluationStr( ...
        CBPdata.groundtruth.spike_time_array_processed, ...
        CBPdata.clustering.spike_time_array_cl, ...
        total_misses_cl, total_false_positives_cl));
    
[total_misses, total_false_positives, prune_est_times, misses, ...
 false_positives] = EvaluateSorting( ...
        CBPdata.CBP.spike_time_array, ...
        CBPdata.CBP.spike_amps, ...
        CBPdata.groundtruth.spike_time_array_processed, ...
        'threshold', CBPdata.amplitude.amp_thresholds, ...
        'location_slack', params.amplitude.spike_location_slack);
fprintf('       CBP: %s', SortingEvaluationStr( ...
        CBPdata.groundtruth.spike_time_array_processed, ...
        prune_est_times, total_misses, ...
        total_false_positives));