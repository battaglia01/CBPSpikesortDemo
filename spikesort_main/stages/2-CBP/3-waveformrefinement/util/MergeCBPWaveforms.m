% This function merges one or more CBP waveforms into one new waveform.
% The new clusters are assigned the index of the lowest-numbered cluster to
% be merged.

function MergeCBPWaveforms(waveform_inds)
global CBPdata params CBPInternals;

CW = CBPdata.waveform_refinement;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have valid waveform indices
assert(min(waveform_inds) >= 1 && max(waveform_inds) <= length(CW.final_waveforms), ...
    'Invalid waveform index!');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% take weighted average of waveforms
new_waveform = 0;
total_instances = 0;
for n=1:length(waveform_inds)
    num_instances = length(CW.spike_time_array_thresholded{waveform_inds(n)});
    total_instances = total_instances + num_instances;
    new_waveform = new_waveform + ...
                   num_instances * CW.final_waveforms{waveform_inds(n)};
end
new_waveform = new_waveform / total_instances;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merge waveforms and delete old indices
new_ind = min(waveform_inds);
old_inds = waveform_inds(waveform_inds ~= new_ind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update CBPdata.waveform_refinement.final_waveforms
CW.final_waveforms{new_ind} = new_waveform;
CW.final_waveforms(old_inds) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now create the new spike time and amplitude arrays
new_stats = [];
for n=1:length(waveform_inds)
    new_stats = [new_stats; ...
        CW.spike_time_array_thresholded{waveform_inds(n)} ...
        CW.spike_time_array_ms_thresholded{waveform_inds(n)} ...
        CW.spike_amps_thresholded{waveform_inds(n)}];
end
new_stats = sortrows(new_stats, 1);

CW.spike_time_array_thresholded{new_ind} = new_stats(:, 1);
CW.spike_time_array_ms_thresholded{new_ind} = new_stats(:, 2);
CW.spike_amps_thresholded{new_ind} = new_stats(:, 3);

CW.spike_time_array_thresholded(old_inds) = [];
CW.spike_time_array_ms_thresholded(old_inds) = [];
CW.spike_amps_thresholded(old_inds) = [];

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
% store in CBPdata and also change number of waveforms
CW.num_waveforms = length(CW.final_waveforms);
CBPdata.waveform_refinement = CW;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lastly, clear stale tabs and replot:
if (params.plotting.calibration_mode)
    ClearStaleTabs('GroundTruth');
    WaveformRefinementPlot;
    ChangeCalibrationTab('Waveform Refinement');
end
