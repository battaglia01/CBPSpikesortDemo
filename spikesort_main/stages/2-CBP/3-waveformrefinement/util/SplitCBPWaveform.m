% This function splits a CBP waveform into one or more sub-waveforms by
% re-clustering on only those snippets assigned to the waveform.
function SplitCBPWaveform(waveform_ind, num_new_waveforms)
global CBPdata params CBPInternals

CW = CBPdata.waveform_refinement;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have valid waveform indices
assert(waveform_ind >= 1 && ...
        waveform_ind <= length(CW.final_waveforms), ...
       'Invalid waveform index!');
assert(num_new_waveforms >= 2, ...
       'Must split waveform into at least two new waveforms!');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get array of times (as samples), shifted to point to the center of the
% waveform peak
waveform = CW.final_waveforms{waveform_ind};
spike_times = CW.spike_time_array_thresholded{waveform_ind};
waveform_square = sum(waveform.^2);
max_offset = mean(find(waveform_square == max(waveform_square)));
peak_times = round(spike_times + max_offset);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build snippets symmetrically (??) from center (look at snippet data)
X = ConstructSnippetMatrix(CBPdata.whitening.data, ...
                           peak_times, ...
                           params.clustering);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% put into PC space for clustering (??)
[PCs, XProj] = TruncatePCs(X, params.clustering.percent_variance);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do KMeans to get new cluster assignments and centroids for each new
% cluster
sub_assignments = DoKMeans(X', num_new_waveforms);
new_centroids = GetCentroids(X, sub_assignments);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get new waveforms
new_waveforms = ...
    waveformMat2Cell(new_centroids, params.general.spike_waveform_len, ...
                     CBPdata.whitening.nchan, ...
                     num_new_waveforms);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Place the first new cluster in the old waveform ID, then append the rest
CW.final_waveforms{waveform_ind} = new_waveforms{1};
CW.final_waveforms(end+1:end+(num_new_waveforms-1)) = {new_waveforms{2:end}};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set spike times, amps, etc. (default amp = 1?)
% first collate the results into a new cell array
tmp_spike_time_array_thresholded = {};
tmp_spike_time_array_ms_thresholded = {};
tmp_spike_amps_thresholded = {};
for n=1:num_new_waveforms
    tmp_spike_time_array_thresholded{n} = ...
        CW.spike_time_array_thresholded{waveform_ind}(sub_assignments == n);
    tmp_spike_time_array_ms_thresholded{n} = ...
        CW.spike_time_array_ms_thresholded{waveform_ind}(sub_assignments == n);
    tmp_spike_amps_thresholded{n} = ...
        ones(nnz(sub_assignments == n), 1);
end

% then update the old cell array
for n=1:num_new_waveforms
    % if it's the first new cluster, replace the old waveform with it,
    % otherwise append
    if n == 1
        ind_to_insert = waveform_ind;
    else
        ind_to_insert = CW.num_waveforms + n - 1;
    end
    CW.spike_time_array_thresholded{ind_to_insert} = ...
        tmp_spike_time_array_thresholded{n};
    CW.spike_time_array_ms_thresholded{ind_to_insert} = ...
        tmp_spike_time_array_ms_thresholded{n};
    CW.spike_amps_thresholded{ind_to_insert} = ...
        tmp_spike_amps_thresholded{n};
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate new spike traces
CW.spike_traces_thresholded = ...
    CreateSpikeTraces(CW.spike_time_array_thresholded, ...
                      CW.spike_amps_thresholded, ...
                      CW.final_waveforms, ...
                      CBPdata.whitening.nsamples, ...
                      CBPdata.whitening.nchan);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% match the new waveforms
CW.cluster_assignment_mtx = ...
    MatchWaveforms(CBPdata.clustering.init_waveforms, ...
                   CW.final_waveforms);
CW.init_assignment_mtx = ...
    MatchWaveforms(CBPdata.CBP.init_waveforms, ...
                   CW.final_waveforms);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update single vectors of (rounded) sample times and assignments
[CW.segment_centers, ...
 CW.assignments] = ...
    GetSpikeVectorsFromTimeCellArray(...
        CW.spike_time_array_thresholded);

% add PCs and so on
[CW.X, ~, ...
 CW.assignments, ...
 CW.PCs, CW.XProj, ~, ~] = ...
    GetAllSpikeInfo(...
        CW.segment_centers, ...
        CW.assignments);
               
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% change num_waveforms and put CW back
CW.num_waveforms = length(CW.final_waveforms);
CBPdata.waveform_refinement = CW;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lastly, clear stale tabs:
ClearStaleTabs('GroundTruth');


% Lastly, clear stale tabs and replot:
if (params.plotting.calibration_mode)
    ClearStaleTabs('GroundTruth');
    WaveformRefinementPlot;
    ChangeCalibrationTab('Waveform Refinement');
end
