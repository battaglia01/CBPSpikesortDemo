%% ----------------------------------------------------------------------------------
% CBP step 2: use CBP to estimate spike times
%
% Calibration for CBP results:
% Fig1: visually compare whitened data, recovered spikes
% Fig2: residual histograms (raw, and cross-channel magnitudes) - compare to Fig3

function SpikeTimingStage
global params dataobj;

fprintf('***CBP Step 2: use CBP to estimate spike times'); %%@New

CBPinfo = dataobj.CBPinfo;

% Turn off the Java progress bar if it causes errors
% params.cbp.progress = false;

[CBPinfo.spike_times, CBPinfo.spike_amps, CBPinfo.recon_snippets] = ...
    SpikesortCBP(CBPinfo.snippets, CBPinfo.snippet_centers, ...
        dataobj.CBPinfo.init_waveforms, params.cbp_outer, params.cbp);

if (params.general.calibration_mode)
    DisplaySortedSpikes(dataobj.whitening, CBPinfo.spike_times, ...
        CBPinfo.spike_amps, dataobj.CBPinfo.init_waveforms, ...
        CBPinfo.snippets, CBPinfo.recon_snippets, params);
end

dataobj.CBPinfo = CBPinfo;

fprintf('***Done CBP step 2.\n\n');
CBPNext('MatchWaveformStage');
