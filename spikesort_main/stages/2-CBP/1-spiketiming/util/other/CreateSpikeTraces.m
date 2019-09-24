function spike_traces = CreateSpikeTraces(spike_times, spike_amps, ...
    spike_waveforms, nsamples, nchan)

    spike_traces = {};

    % put time deltas in the middle chan due to the behavior of
    % conv2(...,...,'same');
    midChan = floor(nchan/2)+1;
    for n=1:length(spike_waveforms)
        spkInds = true(size(spike_times{n})); %%@logical ones
        tInds = spike_times{n}(spkInds);

        trace = zeros(nsamples,nchan);
        trace(round(tInds),midChan) = spike_amps{n}(spkInds)';

        trace = conv2(trace, reshape(spike_waveforms{n},[],nchan), 'same');
        spike_traces{n} = trace;
    end
end