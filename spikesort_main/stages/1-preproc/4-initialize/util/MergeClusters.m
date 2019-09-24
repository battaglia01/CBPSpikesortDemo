function MergeClusters(waveform_inds)
global CBPdata params CBPInternals;

%Check to make sure we have a valid cluster
assert(all(ismember(waveform_inds,CBPdata.clustering.assignments)), ...
    'Invalid cluster index!');

%merge assignments
new_ind = min(waveform_inds);
ind_masks = ismember(CBPdata.clustering.assignments,waveform_inds);
CBPdata.clustering.assignments(ind_masks) = new_ind;

%redo assignment numbers
next_num = 1;
for n=1:max(CBPdata.clustering.assignments)
    assignment_inds = find(CBPdata.clustering.assignments == n);
    if ~isempty(assignment_inds)
        CBPdata.clustering.assignments(assignment_inds) = next_num;
        next_num = next_num + 1;
    end
end

%change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms - (length(waveform_inds) - 1);

%get centroids
CBPdata.clustering.centroids = GetCentroids(CBPdata.clustering.X, CBPdata.clustering.assignments);

%Put them in a canonical order (according to increasing 2norm);
[CBPdata.clustering.centroids, clperm] = OrderWaveformsByNorm(CBPdata.clustering.centroids);
CBPdata.clustering.assignments = PermuteAssignments(...
                                    CBPdata.clustering.assignments, clperm);

%Get initial waveforms
CBPdata.clustering.init_waveforms = ...
    waveformMat2Cell(CBPdata.clustering.centroids, params.general.spike_waveform_len, ...
    CBPdata.whitening.nchan, params.clustering.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
spike_times_cl = GetSpikeTimesFromAssignments( ...
    CBPdata.clustering.segment_centers_cl, CBPdata.clustering.assignments);

if (params.plotting.calibration_mode)
    InitializeWaveformPlot;
end
