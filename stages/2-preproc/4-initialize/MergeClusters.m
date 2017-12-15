function MergeClusters(waveform_inds)
global params dataobj;

%Check to make sure we have a valid cluster
assert(all(ismember(waveform_inds,dataobj.clustering.assignments)), ...
    'Invalid cluster index!');

%merge assignments
new_ind = min(waveform_inds);
ind_masks = ismember(dataobj.clustering.assignments,waveform_inds);
dataobj.clustering.assignments(ind_masks) = new_ind;

%redo assignment numbers
next_num = 1;
for n=1:max(dataobj.clustering.assignments)
    assignment_inds = find(dataobj.clustering.assignments == n);
    if ~isempty(assignment_inds)
        dataobj.clustering.assignments(assignment_inds) = next_num;
        next_num = next_num + 1;
    end
end

%change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms - (length(waveform_inds) - 1);

%get centroids
dataobj.clustering.centroids = GetCentroids(dataobj.clustering.X, dataobj.clustering.assignments);

%Put them in a canonical order (according to increasing 2norm);
[dataobj.clustering.centroids, clperm] = OrderWaveformsByNorm(dataobj.clustering.centroids);
dataobj.clustering.assignments = PermuteAssignments(...
                                    dataobj.clustering.assignments, clperm);

%Get initial waveforms
dataobj.clustering.init_waveforms = ...
    waveformMat2Cell(dataobj.clustering.centroids, params.rawdata.waveform_len, ...
    dataobj.whitening.nchan, params.clustering.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
spike_times_cl = GetSpikeTimesFromAssignments( ...
    dataobj.clustering.segment_centers_cl, dataobj.clustering.assignments);

if (params.general.calibration_mode)
    VisualizeClustering(dataobj.clustering.XProj, ...
        dataobj.clustering.assignments, dataobj.clustering.X, ...
        dataobj.whitening.nchan, ...
        params.clustering.spike_threshold);
end
                              