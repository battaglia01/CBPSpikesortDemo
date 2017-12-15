%% -----------------------------------------------------------------------------------
% CBP step 1: preprocessing
%
% To speed up computation, partition data into "snippets", which will be processed
% independently. Snippets have duration between min/max_snippet_len and are separated
% by "noise zones" in which the RMS of the waveforms does not surpass "threshold" for
% at least "min_separation_len" consecutive samples. Choose a conservative (low)
% threshold to avoid dropping spikes!

function CBPSetupStage
global params dataobj;

fprintf('***CBP Step 1: Initial Setup\n'); %%@New

%set up CBPinfo, init_waveforms
CBPinfo = dataobj.CBPinfo;

[CBPinfo.snippets, CBPinfo.breaks, CBPinfo.snippet_lens, ...
    CBPinfo.snippet_centers, CBPinfo.snippet_idx] = ...
    PartitionSignal(dataobj.whitening.data, params.partition);

dataobj.CBPinfo = CBPinfo;
parout = params;
fprintf('***Done CBP Step 1.\n\n');
CBPNext('SpikeTimingStage')
