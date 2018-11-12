function [centroids, assignments, X, XProj, PCs, peak_idx,...
         init_waveforms, spike_times_cl] = EstimateInitialWaveforms

global dataobj params;

% Use PCA + K-means clustering to get an intial estimate of the waveform
% shapes. Also used to benchmark performance of clustering for spike
% sorting.

params.clustering.align_mode = dataobj.whitening.averaging_method; %%@ Make averaging_method optional

if isempty(params.clustering.window_len)
    params.clustering.window_len = 2*floor(params.rawdata.waveform_len/2)+1;
end

if isempty(params.clustering.peak_len)
    params.clustering.peak_len = floor(params.clustering.window_len / 2);
end


% Root-mean-squared (across channels) of data.
data_rms = sqrt(sum(dataobj.whitening.data.^ 2, 1));

% Clustering parameters
%threshold = 4 * median(data_rms) ./ 0.6745; % robust
%threshold = 4 * std(data_rms);  %**EPS: Don't know where this came from
threshold = params.clustering.spike_threshold;

% Identify time indices of candidate peaks.
peak_idx = FindPeaks(data_rms(:), threshold, params.clustering);
fprintf('Found %d segments exceeding threshold of %.1f.\n', length(peak_idx),threshold);

% Construct a matrix with these windows, upsampled and aligned.
X = ConstructSnippetMatrix(dataobj.whitening.data, peak_idx, params.clustering);

[PCs, XProj] = TruncatePCs(X, params.clustering.percent_variance);

% Do K-means clustering
%%NOTE - we are clustering in the PC space, not the original space
assignments = DoKMeans(XProj, params.clustering.num_waveforms);
centroids = GetCentroids(X, assignments);

% Put them in a canonical order (according to increasing 2norm);
[centroids, clperm] = OrderWaveformsByNorm(centroids);
assignments = PermuteAssignments(assignments, clperm);

init_waveforms = ...
    waveformMat2Cell(centroids, params.rawdata.waveform_len, ...
    dataobj.whitening.nchan, params.clustering.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
spike_times_cl = GetSpikeTimesFromAssignments( ...
    peak_idx, assignments);
