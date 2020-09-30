%==========================================================================
% Preprocessing Step 4: Use clustering to estimate initial spike waveforms
%
% Initialize spike waveforms, using clustering:
%  - collect data segments with L2-norm larger than params.clustering.spike_threshold
%  - align peaks of waveforms within these segments
%  - Perform PCA on these segments, select a subspace containing desired percent of variance
%  - Perform K-means clustering in this subspace
% params.clustering includes:
%  - num_waveforms : number of cells to be recovered
%  - spike_threshold : threshold used to pick spike-containing data segments (in stdevs)
%  - percent_variance : used to determine number of principal components to use for clustering

function InitializeWaveformMain
global CBPdata params CBPInternals;

CBPdata.clustering = [];

CBPdata.CBP.num_passes = 0;

[CBPdata.clustering.centroids, CBPdata.clustering.assignments, ...
 CBPdata.clustering.X, CBPdata.clustering.XProj, CBPdata.clustering.PCs, ...
 CBPdata.clustering.segment_centers, ...
 CBPdata.clustering.init_waveforms, ...
 CBPdata.clustering.spike_time_array_cl] = ...
     EstimateInitialWaveforms(CBPdata.whitening.data, ...
                              CBPdata.whitening.nchan, ...
                              params.general.spike_waveform_len, ...
                              params.clustering);

fprintf('\nTo adjust cluster estimates, type\n');
fprintf('    MergeClusters(waveform_inds)\n')
fprintf('    SplitCluster(waveform_ind, num_new_waveforms)\n\n');
