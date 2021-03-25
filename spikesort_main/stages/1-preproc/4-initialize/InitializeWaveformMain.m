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

% Check if "CBPdata.external" exists first!
% If it does, we use *those* waveforms for our starting clusters.
if ~isfield(CBPdata, "external")
    % Now estimate our initial waveforms.
    % If we have an "overcluster" factor set to something greater than 1, we
    % will need to cluster to a larger number of initial clusters, to be merged
    % below. The way we will do this is to increase num_waveforms beyond its
    % original value, and then slowly reduce it back to its original below.
    % Also do a Quick assertion that the number of desired clusters is at
    % least 1.
    desired_num_waveforms = params.clustering.num_waveforms;
    assert(desired_num_waveforms >= 1, ...
        "Error: Number of desired clusters must be at least 1!");
    params.clustering.num_waveforms = ...
        round(params.clustering.num_waveforms * ...
              params.clustering.overcluster_factor);

    [CBPdata.clustering.centroids, CBPdata.clustering.assignments, ...
     CBPdata.clustering.X, CBPdata.clustering.XProj, CBPdata.clustering.PCs, ...
     CBPdata.clustering.segment_centers, ...
     CBPdata.clustering.init_waveforms, ...
     CBPdata.clustering.spike_time_array_cl] = ...
         EstimateInitialWaveforms(CBPdata.whitening.data, ...
                                  CBPdata.whitening.nchan, ...
                                  params.general.spike_waveform_len, ...
                                  params.clustering);

    % Now, if we have an "overcluster" factor that is greater than one, we
    % successively merge down until we have the desired number of clusters.
    % To do this, we will use the "xcorr" method of determining centroid
    % similarity, even if the user has chosen something else for the plot.

    % First, we want to get rid of any clusters that have either an extremely
    % low number of clusters, which will tend to be sporadic mis-clustered
    % spikes. We also want to keep an eye on any clusters with an extremely
    % high number of spikes, which will tend to be "junk clusters" with a ton
    % of things in one.
    % We will:
    % 1. Drop the sporadic clusters
    % 2. Take note of how many junk clusters there are, and then drop them
    % 3. Do our merges, going even past the number of desired waveforms -
    %    subtract the number of "junk clusters" from the number of desired
    % 4. "Add" however many clusters are remaining for us to get the desired
    %    amount

    % We will take the geometric median and geometric median absolute
    % deviation, and treat any clusters that are (geometrically) more than 3x
    % deviations from the mean as "junk", and any that have less than some
    % threshold as "sporadic"
    %%@ hard-coded to 3x and 20, but could add a parameter for this
    num_spikes = cellfun(@length, CBPdata.clustering.spike_time_array_cl);
    normalized_num_spikes = log(num_spikes) - median(log(num_spikes));
    sporadic_clusters = ...
        find(num_spikes < 20);
    junk_clusters = ...
        find(normalized_num_spikes > 2*mad(normalized_num_spikes, 1));

    % Now make note of the number of junk clusters, and ditch both the junk and
    % sporadic ones. Note our call to "RemoveClusters" changes the value of
    % params.clustering.num_waveforms
    % num_junk_clusters = length(junk_clusters);
    num_junk_clusters = 0; %%@ just to test
    %%@ just try deleting sporadic for now

    %%@, actually delete nothing, just do the merges and see what happens
    to_delete = sporadic_clusters;% union(sporadic_clusters, junk_clusters);
    RemoveClusters(to_delete, false);

    % Now iterate on what remains and do our merges. We will *add* new
    % waveforms for each "junk" cluster at the end, so we want to go *past* the
    % number of desired waveforms so we can *add* them
    num_iterations = ...
        params.clustering.num_waveforms - ...
        desired_num_waveforms;

    for n=1:num_iterations
        % Get similarity scores
        centroid_scores = ...
            MeasureCentroidSimilarity(CBPdata.clustering.centroids, ...
                                      CBPdata.whitening.nchan, ...
                                      "shiftcorr");

        % Get rid of the diagonal, so we don't merge centroids with themselves!
        cur_num_centroids = length(centroid_scores);
        centroid_scores = centroid_scores .* ...
            (ones(cur_num_centroids) - eye(cur_num_centroids));

        %%@ break loop if the max is less than threshold
    %     if max(centroid_scores(:)) < 0.8
    %         break;
    %     end

        % Get the two centroids that need to be merged the most
        [centroid1, centroid2] = ...
            find(centroid_scores == max(centroid_scores(:)));


        % Now merge them!
        MergeClusters([centroid1 centroid2], false);
    end

    % Now that we're done, let's add however many new clusters we need to bring
    % it back to the right number. Note params.clustering.num_waveforms has
    % been updated with the current number after all these merges:
    num_new = desired_num_waveforms - params.clustering.num_waveforms;
    if num_new > 0
        AddClusters(num_new, false);
    end

    % Just make sure that we have the right number of waveforms now:
    %%@ readd
    tmp_num_waveforms = params.clustering.num_waveforms;
    params.clustering.num_waveforms = desired_num_waveforms;
    assert(tmp_num_waveforms == desired_num_waveforms, ...
           "Internal error: incorrect number of waveforms!");
else
% If we got here, then we already imported the clustering and etc data from
% some external spike sorter! Just calculate the various things and put
% that in our clustering sub-object.


        % Get the initial spike info
        [CBPdata.external.X, CBPdata.external.centroids, ...
         CBPdata.external.assignments, CBPdata.external.PCs, ...
         CBPdata.external.XProj, CBPdata.external.init_waveforms, ...
         CBPdata.external.spike_time_array_cl] = ...
            GetAllSpikeInfo(...
                CBPdata.external.segment_centers, ...
                CBPdata.external.assignments);

        CBPdata.clustering = CBPdata.external;
        % Now re-align the centroids and the peak indices
        for n=1:3
            [CBPdata.clustering.X, CBPdata.clustering.XProj, CBPdata.clustering.PCs, ...
             CBPdata.clustering.centroids, CBPdata.clustering.segment_centers] = ...
                AdjustSnippetsToCentroid(CBPdata.whitening.data, ...
                                         CBPdata.clustering.X, ...
                                         CBPdata.clustering.segment_centers, ...
                                         CBPdata.clustering.centroids, ...
                                         CBPdata.clustering.assignments, ...
                                         CBPdata.whitening.nchan, ...
                                         params.clustering);
        end
        % Now get the spike array again
        [CBPdata.clustering.X, CBPdata.clustering.centroids, ...
         CBPdata.clustering.assignments, CBPdata.clustering.PCs, ...
         CBPdata.clustering.XProj, CBPdata.clustering.init_waveforms, ...
         CBPdata.clustering.spike_time_array_cl] = ...
            GetAllSpikeInfo(...
                CBPdata.clustering.segment_centers, ...
                CBPdata.clustering.assignments);

        CBPdata.clustering = CBPdata.external;
end


% Now, if we're in "cheat mode," we also compute how well these waveforms
% match ground truth
if params.ground_truth.cheat_mode
    CBPdata.clustering.cheat_mode.ground_spike_time_array_processed = ...
        GetSpikeTimeCellArrayFromVectors(...
            CBPdata.ground_truth.true_spike_times, ...
            CBPdata.ground_truth.true_spike_class, ...
            CBPdata.filtering.sample_delay);

    [CBPdata.clustering.cheat_mode.best_ordering_cl, ...
     CBPdata.clustering.cheat_mode.miss_mtx_cl, ...
     CBPdata.clustering.cheat_mode.fp_mtx_cl, ...
     CBPdata.clustering.cheat_mode.tp_mtx_cl, ...
     CBPdata.clustering.cheat_mode.all_err_mtx_cl, ...
     CBPdata.clustering.cheat_mode.total_score_mtx_cl] = ...
        ReorderCells( ...
            CBPdata.clustering.cheat_mode.ground_spike_time_array_processed, ...
            CBPdata.clustering.spike_time_array_cl, ...
            params.amplitude.spike_location_slack, ...
            params.ground_truth.balanced);

    [CBPdata.clustering.cheat_mode.total_misses_cl, ...
     CBPdata.clustering.cheat_mode.total_false_positives_cl, ...
     CBPdata.clustering.cheat_mode.total_true_positives_cl, ...
     CBPdata.clustering.cheat_mode.misses_cl, ...
     CBPdata.clustering.cheat_mode.false_positives_cl, ...
     CBPdata.clustering.cheat_mode.true_positives_cl] = EvaluateSortingLowLevel(...
            CBPdata.clustering.spike_time_array_cl, ...
            CBPdata.clustering.cheat_mode.ground_spike_time_array_processed, ...
            CBPdata.clustering.cheat_mode.best_ordering_cl, ...
            params.amplitude.spike_location_slack);
end


fprintf('\nTo adjust cluster estimates, type\n');
fprintf('    MergeClusters(waveform_inds)\n')
fprintf('    SplitCluster(waveform_ind, num_new_waveforms)\n\n');