function SplitCluster(waveform_ind, num_new_waveforms)
global CBPdata params CBPInternals;

%find assignments
ind_mask = (CBPdata.clustering.assignments == waveform_ind);

%redo assignment numbers
inds_to_change = CBPdata.clustering.assignments > waveform_ind;
CBPdata.clustering.assignments(inds_to_change) = ...
    CBPdata.clustering.assignments(inds_to_change) + num_new_waveforms - 1;

%change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms + num_new_waveforms - 1;

%do k-means again
new_assignments = DoKMeans(CBPdata.clustering.XProj(ind_mask,:), num_new_waveforms);

%update assignments
CBPdata.clustering.assignments(ind_mask) = new_assignments + waveform_ind - 1;

%get centroids
CBPdata.clustering.centroids = GetCentroids(CBPdata.clustering.X, ...
                                    CBPdata.clustering.assignments);

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
CBPdata.clustering.spike_times_cl = GetSpikeTimesFromAssignments( ...
    CBPdata.clustering.segment_centers_cl, CBPdata.clustering.assignments);

if (params.plotting.calibration_mode)
    InitializeWaveformPlot;
end
