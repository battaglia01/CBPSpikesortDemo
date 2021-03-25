% Given a set of indices, a cell array of waveforms,
% and a cell array of spike times, this returns a weighted average of the
% waveforms (weighted by how many spikes each one has). This is useful for
% the waveform plots that compare waveforms (e.g. comparing CBP to
% clustering), when one CBP waveform is assigned to multiple clusters.
function out = AveragedWaveform(inds, waveforms, spike_times) 
    out = zeros(size(waveforms(1)));
    
    total_num_spikes = 0;
    for n=inds(:)'
        out = out + waveforms{n} * length(spike_times{n});
        total_num_spikes = total_num_spikes + length(spike_times{n});
    end
    out = out/total_num_spikes;
end