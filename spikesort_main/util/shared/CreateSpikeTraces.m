% returns a "simulated trace" signal for each waveform, obtained by
% convolving the waveform with a spike train of times.
% if "spike_amps" is [], just assume that the amplitudes are all '1'.
%
% function spike_traces = CreateSpikeTraces(spike_time_array, spike_amps, ...
%     spike_waveforms, nsamples, nchan)
function spike_traces = CreateSpikeTraces(spike_time_array, spike_amps, ...
    spike_waveforms, nsamples, nchan)

    spike_traces = {};

    % put time deltas in the middle chan due to the behavior of
    % conv2(...,...,'same');
    midChan = floor(nchan/2)+1;
    for n=1:length(spike_waveforms)
        if isempty(spike_amps)
            cur_amps = ones(size(spike_time_array{n}));
        else
            cur_amps = spike_amps{n};
        end
        spkInds = true(size(spike_time_array{n})); %%@logical ones
        tInds = spike_time_array{n}(spkInds);
        % If we have any spikes at fractional sample indices that would
        % round to 0, just move them to 0.5 so they round to 1
        tInds(tInds < 0.5) = 0.5;

        trace = zeros(nsamples,nchan);
        trace(round(tInds), midChan) = cur_amps(spkInds)';

        trace = conv2(trace, reshape(spike_waveforms{n},[],nchan), 'same');
        spike_traces{n} = trace;
        spike_traces{n} = spike_traces{n}(1:nsamples, :);
    end
end
