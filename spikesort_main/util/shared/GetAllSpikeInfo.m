function [X, centroids, assignments, PCs, XProj, init_waveforms, ...
          spike_time_array_cl] = ...
    GetAllSpikeInfo(segment_centers, assignments, reorder)
    global CBPdata params;
    
    if nargin < 3
        reorder = true;
    end

    % get true number of waveforms from the number of unique assignment
    % ID numbers
    num_waveforms = max(assignments);

    % Now, using this, we build the "X" array:
    %%@ is params.clustering right to use for CBP?
    X = ConstructSnippetMatrix(CBPdata.whitening.data, ...
                               segment_centers, ...
                               params.clustering);

    % Likewise, we get the centroids:
    centroids = GetCentroids(X, assignments);

    % Put centroids in a canonical order (according to increasing 2norm);
    if reorder
        [centroids, clperm] = ...
            OrderWaveformsByNorm(centroids);
        assignments = PermuteAssignments(assignments, clperm, 'inverse');
    end

    % now get PCs and XProj
    [PCs, XProj] = TruncatePCs(X, params.clustering.percent_variance);

    % Get initial waveforms in cell array form
    init_waveforms = ...
        waveformMat2Cell(centroids, params.general.spike_waveform_len, ...
        CBPdata.whitening.nchan, num_waveforms);

    % For later comparisons, also compute spike times corresponding to the segments
    % assigned to each cluster:
    spike_time_array_cl = ...
        GetSpikeTimeCellArrayFromVectors(segment_centers, assignments);

    %%@cleanup
    % lastly, reorganize the CBPdata fields
%     CBPdata.clustering = orderfields(CBPdata.clustering, ...
%         ["centroids", "assignments", "X", "XProj", "PCs", ...
%          "segment_centers", "init_waveforms", "spike_time_array_cl"]);
%
%     % reset number of passes
%     CBPdata.CBP.num_passes = 0;
end
