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
%
% Calibration for waveform initialization:
% Fig 5 shows the data segments projected onto the first two principal components,
% and the identified clusters.  Fig 6 shows the waveforms associated with each
% cluster.  The visualization function also prints out a table of distances between
% waveforms, and each of their distances to the origin (i.e., their norm).  All
% distances are relative to the noise amplitude.  These numbers provide some
% indication of how likely it is that waveforms could be confused with each other, or
% with background noise.
%
% At this point, waveforms of all potential cells should be identified (NOTE:
% spike identification errors are irrelevant - only the WAVEFORMS matter).  If
% not, may need to adjust params.clustering.num_waveforms and re-run the clustering
% to identify more/fewer cells.  May also wish to adjust the
% params.rawdata.waveform_len, increasing it if the waveforms (Fig 5) are being
% chopped off, or shortening it if there is a substantial boundary region of silence.
% If you do this, you should go back and re-run starting from the whitening step,
% since the waveform_len affects the identification of noise regions.

function InitializeWaveformStage
global params dataobj;

fprintf('***Preprocessing Step 4: Estimate initial spike waveforms\n'); %%@New

clustering = [];

[clustering.centroids, clustering.assignments, ...
    clustering.X, clustering.XProj, clustering.PCs, ...
    clustering.segment_centers_cl] = ...
    EstimateInitialWaveforms(dataobj.whitening, params);

clustering.init_waveforms = ...
    waveformMat2Cell(clustering.centroids, params.rawdata.waveform_len, ...
    dataobj.whitening.nchan, params.clustering.num_waveforms);

if (params.general.calibration_mode)
    VisualizeClustering(clustering.XProj, ...
        clustering.assignments, clustering.X, ...
        dataobj.whitening.nchan, ...
        params.clustering.spike_threshold);
end

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
clustering.spike_times_cl = GetSpikeTimesFromAssignments( ...
    clustering.segment_centers_cl, clustering.assignments);

dataobj.clustering = clustering;
parout = params;

fprintf('***Done preprocessing step 4!\n\n');
CBPNext('CBPSetupStage');
