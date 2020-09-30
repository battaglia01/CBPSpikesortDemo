%% ----------------------------------------------------------------------------------
% CBP Step 4: Re-estimate waveforms


function WaveformRefinementMain
global CBPdata params CBPInternals;

% Now that we've updated the thresholds, compute the final spike waveforms.
% Store in CBPdata.waveformrefinement
CBPdata.waveformrefinement = [];
CBPdata.waveformrefinement.final_waveforms = {};
CBPdata.waveformrefinement.num_waveforms = CBPdata.CBP.num_waveforms;

% Compute waveforms using regression, with interpolation (defaults to cubic spline)
nlrpoints = (params.general.spike_waveform_len-1)/2;
for n=1:length(CBPdata.CBP.spike_time_array)
    %%@ original left for reference. Why are we subtracting 1???
    %%@ sts = CBPdata.CBP.spike_time_array{n}(CBPdata.CBP.spike_amps{n} > ...
    %%@                                  CBPdata.amplitude.amp_thresholds(n)) - 1;
    %%@ CBPdata.CBP.final_waveforms{n} = CalcSTA(CBPdata.whitening.data', ...
    %%@                                              sts, [-nlrpoints nlrpoints])';

    % get a bitmask of all the spike indices that exceed threshold level
    amplitudemask = ...
        CBPdata.CBP.spike_amps{n} > CBPdata.amplitude.amp_thresholds(n);

    % get thresholded versions of spike times, amps, etc
    CBPdata.waveformrefinement.spike_time_array_thresholded{n,1} = ...
        CBPdata.CBP.spike_time_array{n}(amplitudemask);
    CBPdata.waveformrefinement.spike_time_array_ms_thresholded{n,1} = ...
        CBPdata.CBP.spike_time_array_ms{n}(amplitudemask);
    CBPdata.waveformrefinement.spike_amps_thresholded{n,1} = ...
        CBPdata.CBP.spike_amps{n}(amplitudemask);

    % Do the interpolation and get the final waveforms
    %%@ Note the - 1 below in the second arg - this is the way it
    %%@ originally was, not sure why. Just leaving it like this.
    CBPdata.waveformrefinement.final_waveforms{n} = ...
        CalcSTA(CBPdata.whitening.data', ...
                CBPdata.waveformrefinement.spike_time_array_thresholded{n} - 1, ...
                [-nlrpoints nlrpoints]);
end

% create thresholded spike traces for use in postproc
CBPdata.waveformrefinement.spike_traces_thresholded = ...
    CreateSpikeTraces(CBPdata.waveformrefinement.spike_time_array_thresholded, ...
                      CBPdata.waveformrefinement.spike_amps_thresholded, ...
                      CBPdata.waveformrefinement.final_waveforms, ...
                      CBPdata.whitening.nsamples, ...
                      CBPdata.whitening.nchan);

% increment the number of passes to waveform refinement - should match CBP
CBPdata.waveformrefinement.num_passes = CBPdata.CBP.num_passes;

% Match waveforms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% match the new waveforms
CBPdata.waveformrefinement.cluster_matching_perm = ...
    MatchWaveforms(CBPdata.clustering.init_waveforms, ...
                   CBPdata.waveformrefinement.final_waveforms);