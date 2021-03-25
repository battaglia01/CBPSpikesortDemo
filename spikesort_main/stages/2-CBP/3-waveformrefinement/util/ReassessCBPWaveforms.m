% This function "removes" all of the other CBP waveforms from the
% signal except the given indices, and then re-clusters the residue. This
% can be helpful if one of the waveforms seems to be noise, or interfered
% with by the other waveforms.

function ReassessCBPWaveforms(waveform_inds)
global CBPdata params CBPInternals;

CW = CBPdata.waveform_refinement;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have valid waveform indices
assert(min(waveform_inds) >= 1 && max(waveform_inds) <= length(CW.final_waveforms), ...
    'Invalid waveform index!');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merge waveforms and delete old indices
old_inds = setdiff(1:length(CW.final_waveforms), waveform_inds);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate combined traces from the old inds to remove, then get residue
traces = 0;
for n=1:length(old_inds)
    traces = traces + CW.spike_traces_thresholded{old_inds(n)}';
end
trace_residue = CBPdata.whitening.data - traces;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now initialize again on the residue
tmp_cluster_pars = params.clustering;
tmp_cluster_pars.num_waveforms = length(waveform_inds);
[centroids, assignments, X, XProj, PCs, peak_idx,...
          init_waveforms, spike_time_array_cl] = ...
          EstimateInitialWaveforms(trace_residue, ...
                                   CBPdata.whitening.nchan, ...
                                   params.general.spike_waveform_len, ...
                                   tmp_cluster_pars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now replace old waveforms with new ones
for n=1:length(waveform_inds)
    % waveform
    CW.final_waveforms{waveform_inds(n)} = init_waveforms{n};

    % spike_time_array_thresholded
    CW.spike_time_array_thresholded{waveform_inds(n)} = ...
        spike_time_array_cl{n};

    % spike_time_array_ms_thresholded
    CW.spike_time_array_ms_thresholded{waveform_inds(n)} = ...
        spike_time_array_cl{n} * CBPdata.whitening.dt;

    % spike_amps_thresholded - set to 1 for now
    CW.spike_amps_thresholded{waveform_inds(n)} = ...
        ones(size(spike_time_array_cl{n}));
end

% spike_traces_thresholded
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
