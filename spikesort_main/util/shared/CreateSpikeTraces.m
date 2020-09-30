% returns a "simulated trace" signal for each waveform, obtained by
% convolving the waveform with a spike train of times.
function spike_traces = CreateSpikeTraces(spike_time_array, spike_amps, ...
    spike_waveforms, nsamples, nchan)

    spike_traces = {};

    % put time deltas in the middle chan due to the behavior of
    % conv2(...,...,'same');
    midChan = floor(nchan/2)+1;
    for n=1:length(spike_waveforms)
        spkInds = true(size(spike_time_array{n})); %%@logical ones
        tInds = spike_time_array{n}(spkInds);
        % If we have any spikes at fractional sample indices that would
        % round to 0, just move them to 0.5 so they round to 1
        tInds(tInds < 0.5) = 0.5;

        trace = zeros(nsamples,nchan);
        trace(round(tInds), midChan) = spike_amps{n}(spkInds)';

        trace = conv2(trace, reshape(spike_waveforms{n},[],nchan), 'same');
        spike_traces{n} = trace;
    end
end