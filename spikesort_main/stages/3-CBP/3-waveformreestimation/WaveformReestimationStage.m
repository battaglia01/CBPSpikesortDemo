%% ----------------------------------------------------------------------------------
% CBP Step 3: Re-estimate waveforms
%
% Calibration for CBP waveforms:
% If recovered waveforms differ significantly from initial waveforms, then algorithm
% has not yet converged.  Execute this and go back to re-run CBP:
%     init_waveforms = waveforms;

function WaveformReestimationStage
global params dataobj;
UpdateStage(@WaveformReestimationStage);

fprintf('***CBP step 3: Re-estimate waveforms\n'); %%@New

CBPinfo = dataobj.CBPinfo;

% Compute waveforms using regression, with interpolation (defaults to cubic spline)
nlrpoints = (params.rawdata.waveform_len-1)/2;
CBPinfo.final_waveforms = cell(size(CBPinfo.spike_times));
for i = 1:numel(CBPinfo.spike_times)
    %%Is this why? You can only increase the threshold, not lower it
    sts = CBPinfo.spike_times{i}(CBPinfo.spike_amps{i} > CBPinfo.amp_thresholds(i)) - 1;
    CBPinfo.final_waveforms{i} = CalcSTA(dataobj.whitening.data', sts, [-nlrpoints nlrpoints]);
end

CBPinfo.first_pass = false;
dataobj.CBPinfo = CBPinfo;

% Compare updated waveforms to initial estimates
if (params.general.calibration_mode)
    WaveformReestimationPlot;
end

fprintf('***Done CBP step 3.\n')
StageInstructions;

fprintf('To do another iteration of CBP, type\n');
fprintf('    CBPNext');
fprintf('\nTo finish CBP and move onto post-analysis, type\n');
fprintf('    SonificationStage\n');
