%% ----------------------------------------------------------------------------------
% Post-analysis: Comparison of CBP to clustering results, and to ground truth (if
% available)

%** indicate which cells match ground truth.

function GroundTruthMain
global CBPdata params CBPInternals;


%% ---------------------------------------------------
% First check if there is ground truth data at all. If not, return
if ~isfield(CBPdata, 'groundtruth') || ...
   ~isfield(CBPdata.groundtruth, 'true_spike_times') || ...
   ~isfield(CBPdata.groundtruth, 'true_spike_class')
    fprintf('\nNOTE - file does not contain all ground truth information.\n')
    fprintf('As a result, some of the post-analysis materials, which require\n');
    fprintf('ground truth, will yield only partial information.\n\n');

    % if these materials aren't all there, just create blank templates for
    % all of them
    CBPdata.groundtruth = [];
    CBPdata.groundtruth.true_spike_times = [];
    CBPdata.groundtruth.true_spike_class = [];
    CBPdata.groundtruth.blank_ground_truth = true;
end

CBPdata.groundtruth.blank_ground_truth = false;
%% ---------------------------------------------------
% If there is ground truth in the file, it is formatted as two arrays:
%   1. the `CBPdata.groundtruth.true_spike_times` object, which has true spike
%      times
%   2. the `CBPdata.groundtruth.true_spike_class` object, which has a spike id #
%      for each corresponding entry in the `true_spike_times` object
%
% For now, we assume that the `true_spike_class` object has spike ID's which are
% natural numbers greater than 1.
%
% As a first step, we are going to reformat this as a cell array, in which
% the n'th entry in the array is the vector of spike times for spike ID #n.
% We will later permute the entries so that the ground truth IDs match
% the clustering IDs in the best possible way.
%
% Also, if during the filtering stage, some group delay was added to the signal,
% that is removed here.
CBPdata.groundtruth.spike_time_array_processed = ...
    GetSpikeTimesFromAssignments(...
        CBPdata.groundtruth.true_spike_times, ...
        CBPdata.groundtruth.true_spike_class, ...
        CBPdata.filtering.sampledelay);

% Now, we have to determine which of our cell ID's match the ground truth ID's.
% Just because ground truth has a certain cell listed as ID #1 doesn't
% necessarily mean that it's going to best match cell ID #1 in our sorting
% thus far.
%
% This routine below determines how to best permute the ground truth ID numbers
% to match our sorting, using the spike times from both sets.
% In particular, we are using the clustering spike time array numbers as the
% standard to match the ground truth numbers to, which we then match with CBP
% later.
%
% Originally, this code changed the original groundtruth_true_spike_times
% and true_spike_class as well to match the new permutation. However, we
% will keep the originals as-is, for ease of comparison when saving, and
% instead only change the spike_time_array_processed array (which has
% already had its spike times shifted as well).
%
% This was the most intensive part of the ground truth calculations, but
% now the linear program we have has sped this up.
%
%%@ - In the future, maybe just have it do one of these to speed this up

% first do clustering comparison
[CBPdata.groundtruth.spike_time_array_processed_cl, ...
 CBPdata.groundtruth.best_ordering_cl, ...
 CBPdata.groundtruth.miss_mtx_cl, ...
 CBPdata.groundtruth.fp_mtx_cl, ...
 CBPdata.groundtruth.all_err_mtx_cl] = ...
    ReorderCells( ...
        CBPdata.groundtruth.spike_time_array_processed, ...
        CBPdata.clustering.spike_time_array_cl, ...
        params.amplitude.spike_location_slack);
 
% then do CBP comparison
[CBPdata.groundtruth.spike_time_array_processed_cbp, ...
 CBPdata.groundtruth.best_ordering_cbp, ...
 CBPdata.groundtruth.miss_mtx_cbp, ...
 CBPdata.groundtruth.fp_mtx_cbp, ...
 CBPdata.groundtruth.all_err_mtx_cbp] = ...
    ReorderCells( ...
        CBPdata.groundtruth.spike_time_array_processed, ...
        CBPdata.waveformrefinement.spike_time_array_thresholded, ...
        params.amplitude.spike_location_slack);
    
% Now have it print the evaluation results (just uses globals for now)
PrintSortingEvaluationResults;