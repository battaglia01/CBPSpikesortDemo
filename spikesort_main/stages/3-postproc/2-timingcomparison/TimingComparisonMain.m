%% ----------------------------------------------------------------------------------
% Timing Comparison: View a plot of the entire electrode data set, with the sorted
% spike times superimposed on top.

function TimingComparisonMain
global CBPdata params CBPInternals
 

% We also want to create the relevant SpikeTraces that will be plotted.
% If ground truth doesn't exist, just make it a blank cell array of {}.
%%@ Note, spike_traces_cbp was created previously so we can use that...
%%@ maybe we should just create all these previously, or else create
%%@ them all here?
spike_traces_cl = CreateSpikeTraces(CBPdata.ground_truth.clustering.spike_time_array_cl, [], ...
                                    CBPdata.ground_truth.clustering.init_waveforms, ...
                                    CBPdata.whitening.nsamples, CBPdata.whitening.nchan);
spike_traces_cbp = CBPdata.waveform_refinement.spike_traces_thresholded;
if isfield(CBPdata.ground_truth, "true_spike_waveforms")
    spike_traces_true = CreateSpikeTraces(CBPdata.ground_truth.spike_time_array_processed, [], ...
                                          CBPdata.ground_truth.true_spike_waveforms, ...
                                          CBPdata.whitening.nsamples, CBPdata.whitening.nchan);
else
    spike_traces_true = {};
end
CBPdata.timing_comparison.spike_traces_cl = spike_traces_cl;
CBPdata.timing_comparison.spike_traces_cbp = spike_traces_cbp;
CBPdata.timing_comparison.spike_traces_true = spike_traces_true;

% If we made it this far, that's it - the rest is all done in
% TimingComparisonPlot.

