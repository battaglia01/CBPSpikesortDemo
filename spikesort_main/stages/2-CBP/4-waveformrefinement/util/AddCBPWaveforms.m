% This function "adds" a new waveform to the existing set without splitting
% an existing waveform. It removes all existing spikes from the signal,
% using the estimated waveforms and estimated times, to obtain an estimated
% residue, and then reclusters the residue
%
%%@ NOTE: this is basically the same as adding a new blank "dummy"
%%@ waveform, then "reassessing" that waveform, which is what we'll do

function AddCBPWaveforms(num_new)
global CBPdata params CBPInternals;

CW = CBPdata.waveformrefinement;

% in case reassessing crashes, save the old one
CWold = CBPdata.waveformrefinement;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have entered a valid number of new waveforms
assert(num_new > 0, ...
    'Invalid entry! Please enter a number of new waveforms greater than 0!');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add blank "dummy" waveform and change number of waveforms
for n=1:num_new
    CW.final_waveforms{end+1} = zeros(size(CW.final_waveforms{1}));
    CW.spike_time_array_thresholded{end+1} = [];
    CW.spike_time_array_ms_thresholded{end+1} = [];
    CW.spike_amps_thresholded{end+1} = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate new spike traces
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
old_num_waveforms = CW.num_waveforms;
CW.num_waveforms = length(CW.final_waveforms);
CBPdata.waveformrefinement = CW;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now "reassess"
try
    ReassessCBPWaveforms(old_num_waveforms + [1:num_new]);
catch err
    % if this doesn't go right, put things back the way they were
    CBPdata.waveformrefinement = CWold;
    rethrow(err);
end

% normally we'd re-match the waveforms and re-plot, but
% ReassessCBPWaveforms already does that, so we exit