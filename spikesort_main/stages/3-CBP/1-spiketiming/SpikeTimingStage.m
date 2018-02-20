%% ----------------------------------------------------------------------------------
% CBP step 1: use CBP to estimate spike times
%
% Calibration for CBP results:
% Fig1: visually compare whitened data, recovered spikes
% Fig2: residual histograms (raw, and cross-channel magnitudes) - compare to Fig3

function SpikeTimingStage
global params dataobj;
UpdateStage(@SpikeTimingStage);

fprintf('***CBP Step 1: use CBP to estimate spike times\n'); %%@New
fprintf('***Seeding new initial waveforms with previous final waveforms...\n');

CBPinfo = dataobj.CBPinfo;

%set up CBPinfo, init_waveforms
if CBPinfo.first_pass
    CBPinfo.init_waveforms = dataobj.clustering.init_waveforms;
else
    CBPinfo.init_waveforms = dataobj.CBPinfo.final_waveforms;
    CBPinfo.final_waveforms = {};
end

%Partition the signal into snippets
[CBPinfo.snippets, CBPinfo.breaks, CBPinfo.snippet_lens, ...
    CBPinfo.snippet_centers, CBPinfo.snippet_idx] = ...
    PartitionSignal(dataobj.whitening.data, params.partition);

%Get spike times
[CBPinfo.spike_times, CBPinfo.spike_amps, CBPinfo.recon_snippets] = ...
    SpikesortCBP(CBPinfo.snippets, CBPinfo.snippet_centers, ...
        CBPinfo.init_waveforms, params.cbp_outer, params.cbp);

%convert to ms
CBPinfo.spike_times_ms = {};
for n=1:length(CBPinfo.spike_times)
    CBPinfo.spike_times_ms{n} = CBPinfo.spike_times{n} * dataobj.whitening.dt;
end
CBPinfo.spike_times_ms = CBPinfo.spike_times_ms';

dataobj.CBPinfo = CBPinfo;

%Visualize spikes
if (params.general.calibration_mode)
    SpikeTimingPlot;
end

fprintf('***Done CBP step 1.\n\n');
StageInstructions;