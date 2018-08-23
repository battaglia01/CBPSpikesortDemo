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

CBPinfo = dataobj.CBPinfo;

%set up CBPinfo, init_waveforms
if CBPinfo.first_pass
    fprintf('***Using initial estimates as CBP starting point...\n');
    CBPinfo.init_waveforms = dataobj.clustering.init_waveforms;
    CBPinfo.final_waveforms = {};
else
    fprintf('***Seeding new initial waveforms with previous final waveforms...\n');
    %check to make sure we haven't already shifted final_waveforms
    %into init_waveforms
    if ~isempty(CBPinfo.final_waveforms)
        CBPinfo.init_waveforms = dataobj.CBPinfo.final_waveforms;
        CBPinfo.final_waveforms = {};    
    end
end

%Partition the signal into snippets
[CBPinfo.snippets, CBPinfo.breaks, CBPinfo.snippet_lens, ...
    CBPinfo.snippet_centers, CBPinfo.snippet_idx] = ...
    PartitionSignal(dataobj.whitening.data, params.partition);

%Get spike times
[CBPinfo.spike_times, CBPinfo.spike_times_ms, CBPinfo.spike_amps, CBPinfo.recon_snippets] = ...
    SpikesortCBP(CBPinfo.snippets, CBPinfo.snippet_centers, ...
        CBPinfo.init_waveforms, params.cbp_outer, params.cbp, dataobj.whitening.dt);

%Create spike traces
CBPinfo.spike_traces_init = CreateSpikeTraces(CBPinfo.spike_times, CBPinfo.spike_amps, ...
        CBPinfo.init_waveforms, dataobj.whitening.nsamples, dataobj.whitening.nchan);

dataobj.CBPinfo = CBPinfo;

%Visualize spikes
if (params.general.calibration_mode)
    SpikeTimingPlot;
end

fprintf('***Done CBP step 1.\n\n');
StageInstructions;