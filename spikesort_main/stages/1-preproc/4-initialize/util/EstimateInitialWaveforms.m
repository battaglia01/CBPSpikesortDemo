function [centroids, assignments, X, XProj, PCs, peak_idx,...
          init_waveforms, spike_time_array_cl] = ...
            EstimateInitialWaveforms(whitened_data, nchan, waveform_len, ...
                                     cluster_pars)
% Use PCA + K-means clustering to get an initial estimate of the waveform
% shapes. Also used to benchmark performance of clustering for spike
% sorting.
%
% Outputs:
%   `centroids` are the cluster centroids (i.e. average of snippets in each cluster)
%   `assignments` is a vector of cluster ID's for each snippet
%       corresponding to clusters in `X` below
%   `X` is a matrix in which each column is a snippet
%   `XProj` is a matrix in which each *row* (!!) is a projected snippet
%       in the PC space (due to obscure MATLAB compatibility reasons)
%   `PCs` is a matrix in which each *column* is a PC
%   `peak_idx` is a vector of peaks/segment centers for the snippets
%   `init_waveforms` is a de-vectorized version of `centroids`; a cell
%       array of centroids
%   `spike_time_array_cl` is a cell array of spike times, taken from the
%       `assignments` and `peak_idx` arrays

% Root-mean-squared (across channels) of data.
%%@ Mike's note: this is really a root-sum-squared, not a root-mean-squared
data_L2_across_channels = sqrt(sum(whitened_data.^2, 1));    %%@ RMS vs L2?

% Clustering parameters
%%@MIKE'S NOTE - the below were older versions, leaving here for reference
%%threshold = 4 * median(data_rms) ./ 0.6745; % robust
%%threshold = 4 * std(data_rms);  %**EPS: Don't know where this came from
threshold = cluster_pars.spike_threshold;
L2_adjusted_threshold = ConvertLinfThresholdToL2(threshold, nchan);

% Identify time indices of candidate peaks.
peak_idx = FindPeaks(data_L2_across_channels(:), L2_adjusted_threshold, ...
                     cluster_pars);
fprintf('Found %d segments exceeding threshold of %.1f.\n', ...
        length(peak_idx), threshold);
    
[X, XProj, PCs, centroids, assignments, init_waveforms, ...
    spike_time_array_cl, peak_idx] = ...
        ClusterFromPeaks(whitened_data, peak_idx, waveform_len, ...
                         nchan, cluster_pars);


