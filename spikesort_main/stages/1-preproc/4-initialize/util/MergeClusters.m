% This function merges one or more clusters into one cluster.
% The new clusters are assigned the index of the lowest-numbered cluster to
% be merged.

function MergeClusters(waveform_inds)
global CBPdata params CBPInternals;

% first make sure all waveform_inds are unique and sorted
waveform_inds = sort(unique(waveform_inds));

% Check to make sure we have more than one cluster to merge
assert(length(waveform_inds) > 1, ...
       ['Invalid entry! Please make sure to enter more than one cluster!']); 

% Check to make sure we have valid clusters
assert(all(ismember(waveform_inds, 1:length(CBPdata.clustering.init_waveforms))), ...
       ['Invalid clusters! Are you sure you entered a space-delimited list, ' ...
       'from clusters 1 to ' num2str(params.clustering.num_waveforms) '?']);

% now, for each of the waveforms to be merged, get the estimated time shift
% and shift the spike time indices accordingly.
% we start with the first centroid and compare the second centroid, then
% shift the time indices of the second and merge with the first, and then
% make the result the new "growing_centroid" and keep going
growing_centroid = CBPdata.clustering.centroids(:, waveform_inds(1));
growing_inds = CBPdata.clustering.assignments == waveform_inds(1);

new_ind = min(waveform_inds);
for n=2:length(waveform_inds)
    % compare the next centroid to the growing centroid
    cur_centroid = CBPdata.clustering.centroids(:, waveform_inds(n));
    [c, lags] = xcorr(growing_centroid, cur_centroid);
    
    % this is the amount to shift the current waveform to match the growing
    % centroid
    timeshift = lags(c == max(c));
    
    % now get the indices corresponding to the current centroid
    cur_inds = CBPdata.clustering.assignments == waveform_inds(n);
    
    % now shift the segment_centers accordingly
    CBPdata.clustering.segment_centers(cur_inds) = ...
        CBPdata.clustering.segment_centers(cur_inds) + timeshift;
    
    % make sure there's no underflow or overflow
    too_early = CBPdata.clustering.segment_centers < 1;
    CBPdata.clustering.segment_centers(too_early) = 1;
    too_late = ...
        CBPdata.clustering.segment_centers > ...
            (CBPdata.whitening.nsamples - params.general.spike_waveform_len);
    CBPdata.clustering.segment_centers(too_late) = ...
        CBPdata.whitening.nsamples - params.general.spike_waveform_len;
    
    % update `X` snippet times accordingly
    CBPdata.clustering.X(:, cur_inds) = ...
        ConstructSnippetMatrix(CBPdata.whitening.data, ...
                               CBPdata.clustering.segment_centers(cur_inds), ...
                               params.clustering);
    
    % now merge time indices and get the new centroid
    CBPdata.clustering.assignments(cur_inds) = new_ind;
    growing_inds = growing_inds | cur_inds;
    growing_centroid = ...
        GetCentroids(CBPdata.clustering.X(:, growing_inds), ...
                     CBPdata.clustering.assignments(growing_inds));
end

% now that we've done the above, re-sort the segment_centers, as well as
% assignments and etc
[CBPdata.clustering.segment_centers, new_order] = ...
    sort(CBPdata.clustering.segment_centers);
CBPdata.clustering.assignments = CBPdata.clustering.assignments(new_order);
CBPdata.clustering.X = CBPdata.clustering.X(:, new_order);

% now update PCs and XProj
[CBPdata.clustering.PCs, CBPdata.clustering.XProj] = ...
    TruncatePCs(CBPdata.clustering.X, params.clustering.percent_variance);

% redo assignment numbers
next_num = 1;
for n=1:max(CBPdata.clustering.assignments)
    assignment_inds = find(CBPdata.clustering.assignments == n);
    if ~isempty(assignment_inds)
        CBPdata.clustering.assignments(assignment_inds) = next_num;
        next_num = next_num + 1;
    end
end

% change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms - (length(waveform_inds) - 1);

% get updated centroids
CBPdata.clustering.centroids = GetCentroids(CBPdata.clustering.X, ...
                                            CBPdata.clustering.assignments);

% Put them in a canonical order (according to increasing 2norm);
[CBPdata.clustering.centroids, clperm] = ...
    OrderWaveformsByNorm(CBPdata.clustering.centroids);
CBPdata.clustering.assignments = ...
    PermuteAssignments(CBPdata.clustering.assignments, clperm, 'inverse');

% Get initial waveforms in cell array form
CBPdata.clustering.init_waveforms = ...
    waveformMat2Cell(CBPdata.clustering.centroids, params.general.spike_waveform_len, ...
    CBPdata.whitening.nchan, params.clustering.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
CBPdata.clustering.spike_time_array_cl = GetSpikeTimesFromAssignments( ...
    CBPdata.clustering.segment_centers, CBPdata.clustering.assignments);

% reset number of passes
CBPdata.CBP.num_passes = 0;

% Lastly, clear stale tabs and replot:
if (params.plotting.calibration_mode)
    clusteringstage = GetStageFromName('InitializeWaveform');
    ClearStaleTabs(clusteringstage.next);
    InitializeWaveformPlot;
    ChangeCalibrationTab('Initial Waveforms, Shapes');
end
