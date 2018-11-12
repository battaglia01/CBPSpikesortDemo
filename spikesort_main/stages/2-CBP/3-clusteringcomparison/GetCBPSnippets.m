% Gets a set of waveform "snippets" from a set of CBP spiketimes.
% Also computes the projected PC representation (from the previous clustering
% PC space)
function [X_CBP, CBP_assignments, XProj_CBP] = GetCBPSnippets
global dataobj params;

if isempty(params.clustering.window_len)
    params.clustering.window_len = 2*floor(params.rawdata.waveform_len/2)+1;
end
wlen = floor(params.clustering.window_len / 2);

X_CBP = [];
CBP_assignments = [];
for s=1:length(dataobj.CBPinfo.spike_times)
    for n=1:length(dataobj.CBPinfo.spike_times{s})
        %if index would fall off the beginning or end of the waveform,
        %drop it
        if dataobj.CBPinfo.spike_times{s}(n) < wlen + 1 || ...
           dataobj.CBPinfo.spike_times{s}(n) > dataobj.whitening.nsamples - (wlen + 1)
            continue;
        end

        %if spike amplitude is below amp threshold, drop it
        if dataobj.CBPinfo.spike_amps{s}(n) < dataobj.CBPinfo.amp_thresholds(s)
          continue;
        end

        snip_begin = round(dataobj.CBPinfo.spike_times{s}(n) - wlen);
        snip_end = round(dataobj.CBPinfo.spike_times{s}(n) + wlen);
        snippet = dataobj.whitening.data(:, snip_begin:snip_end);

        X_CBP = [X_CBP reshape(snippet',[],1)];
        CBP_assignments = [CBP_assignments;s];
    end
end

XProj_CBP = X_CBP' * dataobj.clustering.PCs;
