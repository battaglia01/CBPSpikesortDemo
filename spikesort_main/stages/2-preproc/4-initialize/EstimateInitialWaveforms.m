function [centroids, assignments, X, XProj, PCs, peak_idx,...
         init_waveforms, spike_times_cl] = EstimateInitialWaveforms(whitening, params)

% Use PCA + K-means clustering to get an intial estimate of the waveform
% shapes. Also used to benchmark performance of clustering for spike
% sorting.
%

params.clustering.align_mode = whitening.averaging_method; %%@ Make averaging_method optional

if isempty(params.clustering.window_len)
    params.clustering.window_len = 2*floor(params.rawdata.waveform_len/2)+1;
end

if isempty(params.clustering.peak_len)
    params.clustering.peak_len = floor(params.clustering.window_len / 2);
end


% Root-mean-squared (across channels) of data.
data_rms = sqrt(sum(whitening.data.^ 2, 1));

% Clustering parameters
%threshold = 4 * median(data_rms) ./ 0.6745; % robust
%threshold = 4 * std(data_rms);  %**EPS: Don't know where this came from
threshold = params.clustering.spike_threshold;

% Identify time indices of candidate peaks.
peak_idx = FindPeaks(data_rms(:), threshold, params.clustering);
fprintf('Found %d segments exceeding threshold of %.1f.\n', length(peak_idx),threshold);

% Construct a matrix with these windows, upsampled and aligned.
X = ConstructSnippetMatrix(whitening.data, peak_idx, params.clustering);

[PCs, XProj] = TruncatePCs(X, params.clustering.percent_variance);

% Do K-means clustering
%%@WTF, is this right? on the PCAs?
assignments = DoKMeans(XProj, params.clustering.num_waveforms);
centroids = GetCentroids(X, assignments);

% Put them in a canonical order (according to increasing 2norm);
[centroids, clperm] = OrderWaveformsByNorm(centroids);
assignments = PermuteAssignments(assignments, clperm);

init_waveforms = ...
    waveformMat2Cell(centroids, params.rawdata.waveform_len, ...
    whitening.nchan, params.clustering.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
spike_times_cl = GetSpikeTimesFromAssignments( ...
    peak_idx, assignments);

%% Subroutines

% Find peaks (i.e. values greater than any other value within
% pars.peak_len samples).
function peak_idx = FindPeaks(data_rms, threshold, pars)
if (size(data_rms, 2) > 1)
    error('FindPeaks: can only find peaks in a vectorized signal!');
end
peak_idx = data_rms > threshold;

% Don't include borders
peak_idx(1 : pars.window_len) = false;
peak_idx(end - pars.window_len : end) = false;
for i = -pars.peak_len : pars.peak_len
    peak_idx = peak_idx & data_rms >= circshift(data_rms, i);
end
peak_idx = find(peak_idx);


% Get principal components accounting for desired percent variance
% Return the PCs as well as the projections of the data on to these PCs
% (PX)
function [PCs, XProj] = TruncatePCs(X, percent_variance)
fprintf('Doing PCA...');
% Get PCs
if exist('pca', 'file')
    %[PCs, Xproj, latent] = pca(X');
    [PCs, Xproj, latent] = pca(X', 'Centered', false);
else
    [PCs, Xproj, latent] = princomp(X');
    origin = mean(X');
    PCs = PCs + repmat(origin', 1, size(PCs,2));
    Xproj = Xproj + repmat(origin, size(Xproj,1), 1);
end


[latent sorted_idx] = sort(latent, 'descend');
PCs = PCs(:,sorted_idx);
Xproj = Xproj(:, sorted_idx);

% Figure out how many PCs we need to account for
% the desired percent of total variance
cutoff = find(cumsum(latent) ./ sum(latent) * 100 > percent_variance, 1);
npcs = max(2, cutoff);
fprintf('%d/%d PCs account for %.2f percent variance\n', ...
        npcs, length(latent), percent_variance);
% Project onto leading npcs PCs
PC = PCs(:, 1 : npcs);
% Project on to PCs
XProj = Xproj(:, 1 : npcs);