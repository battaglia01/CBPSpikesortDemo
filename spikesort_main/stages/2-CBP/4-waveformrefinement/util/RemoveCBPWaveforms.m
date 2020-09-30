% This function removes CBP waveforms by simply deleting them and removing all of
% the spike times. It is recommended that this step be performed
% last, as subsequent operations may "rediscover" these clusters in
% the data.

function RemoveCBPWaveforms(waveform_inds)
global CBPdata params CBPInternals;

CW = CBPdata.waveformrefinement;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have valid waveform indices
assert(min(waveform_inds) >= 1 && max(waveform_inds) <= length(CW.final_waveforms), ...
    'Invalid waveform index!');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update CBPdata.waveformrefinement subobjects, and re-create spike traces 
CW.final_waveforms(waveform_inds) = [];
CW.spike_time_array_thresholded(waveform_inds) = [];
CW.spike_time_array_ms_thresholded(waveform_inds) = [];
CW.spike_amps_thresholded(waveform_inds) = [];
CW.spike_traces_thresholded = ...
    CreateSpikeTraces(CW.spike_time_array_thresholded, ...
                      CW.spike_amps_thresholded, ...
                      CW.final_waveforms, ...
                      CBPdata.whitening.nsamples, ...
                      CBPdata.whitening.nchan);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% match the new waveforms
CW.cluster_matching_perm = ...
    MatchWaveforms(CBPdata.clustering.init_waveforms, ...
                   CW.final_waveforms);
                  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% store in CBPdata and also change number of waveforms
CW.num_waveforms = length(CW.final_waveforms);
CBPdata.waveformrefinement = CW;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lastly, clear stale tabs and replot:
if (params.plotting.calibration_mode)
    ClearStaleTabs('GroundTruth');
    WaveformRefinementPlot;
    ChangeCalibrationTab('Waveform Refinement');
end
