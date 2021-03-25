% This function is a simple script that prints the results of how well the
% current sorting permutation assignment labels match those of ground
% truth.
function PrintSortingEvaluationResults
global CBPdata params CBPInternals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print the current sorting permutation for Clustering
fprintf('\n');
fprintf('*** CLUSTERING RESULTS ***\n');
fprintf('Best-fit Assignment Matrix:\n');
fprintf('(Rows are estimated, Cols are true, a "1" indicates a pairing)\n');
disp(num2str(CBPdata.ground_truth.best_ordering_cl));
fprintf('\n');

% Then print the error matrices
fprintf('False negative assignment matrix:\n');
disp(CBPdata.ground_truth.miss_mtx_cl);
fprintf('False positive assignment matrix:\n');
disp(CBPdata.ground_truth.fp_mtx_cl);
fprintf('Total error assignment matrix:\n');
disp(CBPdata.ground_truth.all_err_mtx_cl);
fprintf('\n');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print the current sorting permutation for CBP
fprintf('\n');
fprintf('*** CBP RESULTS ***\n');
fprintf('Best-fit Assignment Matrix:\n');
fprintf('(Rows are estimated, Cols are true, a "1" indicates a pairing)\n');
disp(num2str(CBPdata.ground_truth.best_ordering_cbp));
fprintf('\n');

% Then print the error matrices
fprintf('False negative assignment matrix:\n');
disp(CBPdata.ground_truth.miss_mtx_cbp);
fprintf('False positive assignment matrix:\n');
disp(CBPdata.ground_truth.fp_mtx_cbp);
fprintf('Total error assignment matrix:\n');
disp(CBPdata.ground_truth.all_err_mtx_cbp);
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print summary of both results
fprintf('=Clustering Results=\n\t%s', SortingEvaluationStr( ...
        CBPdata.ground_truth.spike_time_array_processed, ...
        CBPdata.clustering.spike_time_array_cl, ...
        CBPdata.ground_truth.total_true_positives_cl, ...
        CBPdata.ground_truth.total_misses_cl, ...
        CBPdata.ground_truth.total_false_positives_cl));

fprintf('=CBP Results=\n\t%s', SortingEvaluationStr( ...
        CBPdata.ground_truth.spike_time_array_processed, ...
        CBPdata.waveform_refinement.spike_time_array_thresholded, ...
        CBPdata.ground_truth.total_true_positives_cbp, ...
        CBPdata.ground_truth.total_misses_cbp, ...
        CBPdata.ground_truth.total_false_positives_cbp));