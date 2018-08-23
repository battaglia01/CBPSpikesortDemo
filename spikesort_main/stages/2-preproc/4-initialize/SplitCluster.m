function SplitCluster(waveform_ind, num_new_waveforms)
global params dataobj;

%find assignments
ind_mask = (dataobj.clustering.assignments == waveform_ind);

%redo assignment numbers
inds_to_change = dataobj.clustering.assignments > waveform_ind;
dataobj.clustering.assignments(inds_to_change) = ...
    dataobj.clustering.assignments(inds_to_change) + num_new_waveforms - 1;

%change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms + num_new_waveforms - 1;

%do k-means again
new_assignments = DoKMeans(dataobj.clustering.XProj(ind_mask,:), num_new_waveforms);

%update assignments
dataobj.clustering.assignments(ind_mask) = new_assignments + waveform_ind - 1;

%get centroids
dataobj.clustering.centroids = GetCentroids(dataobj.clustering.X, ...
                                    dataobj.clustering.assignments);

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
dataobj.clustering.spike_times_cl = GetSpikeTimesFromAssignments( ...
    dataobj.clustering.segment_centers_cl, dataobj.clustering.assignments);

if (params.general.calibration_mode)
    InitializeWaveformPlot;
end
