% This function splits a clusters into one or more sub-clusters by
% re-clustering on only those snippets assigned to the cluster.
function SplitCluster(waveform_ind, num_new_waveforms, do_plot)
global CBPdata params CBPInternals

if nargin < 3
    do_plot = true;
end

% Check to make sure we're only splitting one cluster
assert(length(waveform_ind) == 1, ...
       'Invalid entry! Please enter only one cluster to split.');

% Check to make sure we have a valid cluster
assert(ismember(waveform_ind, 1:params.clustering.num_waveforms) && ...
       num_new_waveforms >= 1, ...
      ['Invalid entry! Are you sure you entered a cluster from ' ...
       '1 to ' num2str(params.clustering.num_waveforms) ...
        ' and a number of splits at least 2?']);

% find assignments
ind_mask = (CBPdata.clustering.assignments == waveform_ind);

% redo assignment numbers
inds_to_change = CBPdata.clustering.assignments > waveform_ind;
CBPdata.clustering.assignments(inds_to_change) = ...
    CBPdata.clustering.assignments(inds_to_change) + num_new_waveforms - 1;

% change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms + num_new_waveforms - 1;

% do k-means again
new_assignments = DoKMeans(CBPdata.clustering.XProj(ind_mask,:), num_new_waveforms);

% update assignments
CBPdata.clustering.assignments(ind_mask) = new_assignments + waveform_ind - 1;

% get centroids
CBPdata.clustering.centroids = GetCentroids(CBPdata.clustering.X, ...
                                            CBPdata.clustering.assignments);

% Put them in a canonical order (according to increasing 2norm);
[CBPdata.clustering.centroids, clperm] = OrderWaveformsByNorm(CBPdata.clustering.centroids);
CBPdata.clustering.assignments = PermuteAssignments(...
                                    CBPdata.clustering.assignments, clperm, ...
                                    'inverse');

% Get initial waveforms
CBPdata.clustering.init_waveforms = ...
    waveformMat2Cell(CBPdata.clustering.centroids, params.general.spike_waveform_len, ...
    CBPdata.whitening.nchan, params.clustering.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
CBPdata.clustering.spike_time_array_cl = GetSpikeTimeCellArrayFromVectors( ...
    CBPdata.clustering.segment_centers, CBPdata.clustering.assignments);

% reset number of passes
CBPdata.CBP.num_passes = 0;

% Lastly, clear stale tabs and replot:
if params.plotting.calibration_mode && do_plot
    clusteringstage = GetStageFromName('InitializeWaveform');
    ClearStaleTabs(clusteringstage.next);
    InitializeWaveformPlot;
    ChangeCalibrationTab('Initial Waveforms, Shapes');
end
