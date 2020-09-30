% This function takes the whitened data, a set of peak indices, and some
% parameters, and returns the adjusted clusters
function [X, XProj, PCs, centroids, assignments, init_waveforms, ...
          spike_time_array_cl] = ...
            ClusterFromPeaks(whitened_data, peak_idx, waveform_len, ...
                             nchan, cluster_pars)

% Construct a matrix with these windows, upsampled and aligned.
X = ConstructSnippetMatrix(whitened_data, peak_idx, cluster_pars);

if isempty(X)
    error("ERROR: No spikes found in initial clustering stage! " + ...
          "This often happens because params.clustering.spike_threshold " + ...
          "is set too high. Try again after adjusting this parameter!");
end

[PCs, XProj] = TruncatePCs(X, cluster_pars.percent_variance);

% Do K-means clustering
% NOTE - we are clustering in the PC space, not the original space
%%@ Mike's note -
%%@ These are the original assignments/centroids *before* we permute
%%@ according to the L2 norm. These numbers change below
%origassignments = DoKMeans(X', cluster_pars.num_waveforms);
waveform_len = size(X, 1)/nchan;
if cluster_pars.kmean_mode == "temporal"
    origassignments = DoKMeans(X', cluster_pars.num_waveforms);
elseif cluster_pars.kmean_mode == "spectral"
    % zero-pad each channel of the flattened snippets, so that we aren't
    % (implicitly) circularly-convolving samples from one channel onto the
    % next when we take the magnitude spectrum
    XX = [];
    for n=1:nchan
        start_ind = (n-1)*waveform_len + 1;
        end_ind = start_ind + waveform_len - 1;
        X_frag = X(start_ind:end_ind, :);
        XX = [XX; X_frag; zeros(size(X_frag))];
    end
    f_XX = fft(XX);
    f_XX = abs(f_XX).^2;
    origassignments = DoKMeans(f_XX', cluster_pars.num_waveforms);
elseif cluster_pars.kmean_mode == "gdadjust"
    %%@ NOTE: it should, in principle, be possible to do a kind of
    %%@ time-shifted clustering by getting the unwrapped phase, and
    %%@ then zeroing the linear term (which centers the waveform near 0).
    %%@ However, this doesn't seem to work as well as expected: everything
    %%@ is in one big cluster, with a few outliers. Using k-medoids rather
    %%@ than k-means doesn't seem to make anything better. This is just
    %%@ left for reference as an undocumented option.
    % first, we get the FFT of each snippet, sufficiently padded.
    % to do this properly, we need to "un-flatten" the waveforms,
    % get the FFT, then re-flatten the FFTs
    pad = 8;
    f_XX = [];
    for n=1:size(X, 2)
        tmp_snip = X(:, n);
        tmp_waveform = reshape(tmp_snip, waveform_len, nchan);
        f_tmp_waveform = fft(tmp_waveform, pad*waveform_len);
        f_XX(:, n) = f_tmp_waveform(:);
    end
    
    % now we want to project away the linear component of the phase
    % response. To do this, first get magnitude and angle
    m_XX = abs(f_XX);
    a_XX = unwrap(angle(f_XX));
    
    % then build a rejection matrix that zeros the linear term
    linterm = repmat((0:(pad*waveform_len-1))', nchan, 1);
    P_linterm = (linterm*linterm')/(linterm'*linterm);
    R_linterm = eye(size(P_linterm)) - P_linterm;
    
    % do the zeroing, then convert back to f_XX
    a_XX = R_linterm * a_XX;
    f_XX = m_XX .* exp(i*a_XX);
    
    % now, to convert back to XX, we have to again unflatten, take the
    % ifft, and then re-flatten
    XX = [];
    for n=1:size(f_XX, 2)
        f_tmp_snip = f_XX(:, n);
        f_tmp_waveform = reshape(f_tmp_snip, pad*waveform_len, nchan);
        tmp_waveform = real(ifft(f_tmp_waveform));
        XX(:, n) = tmp_waveform(:);
    end
    % now we simply do the K-means on our adjusted waveforms
    origassignments = DoKMeans(XX', cluster_pars.num_waveforms);
end
origcentroids = GetCentroids(X, origassignments);

% Put them in a canonical order (according to largest 2norm)
[centroids, clperm] = OrderWaveformsByNorm(origcentroids);

% Now permute the assignments. Note that we need the *inverse* permutation
% for this, so that, for instance, all assignments formerly pointing to label 1
% now point to whichever new position label 1 moved to, *not* whichever new
% label is now in position 1!
assignments = PermuteAssignments(origassignments, clperm, 'inverse');

init_waveforms = ...
    waveformMat2Cell(centroids, waveform_len, nchan, ...
                     cluster_pars.num_waveforms);

% For later comparisons, also compute spike times corresponding to the segments
% assigned to each cluster:
spike_time_array_cl = GetSpikeTimesFromAssignments(peak_idx, assignments);
