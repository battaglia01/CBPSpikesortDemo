%% ----------------------------------------------------------------------------------
% CBP step 3: Comparison of CBP to clustering results

function ClusteringComparisonMain
global CBPdata params CBPInternals;

% First, assemble a "snippet" matrix from the CBP spike times, as well as
% a tag for which spike it came from

% Gets a set of waveform "snippets" from a set of CBP spiketimes.
% Also computes the projected PC representation (from the previous clustering
% PC space)
if isempty(params.clustering.window_len)
    params.clustering.window_len = 2 * floor(params.general.spike_waveform_len/2)+1;
end
wlen = floor(params.clustering.window_len / 2);

X_CBP = [];
CBP_assignments = [];
for s = 1:length(CBPdata.CBP.spike_times)
    for n = 1:length(CBPdata.CBP.spike_times{s})
        %if index would fall off the beginning or end of the waveform,
        %drop it
        if CBPdata.CBP.spike_times{s}(n) < wlen + 1 ...
           || CBPdata.CBP.spike_times{s}(n) > CBPdata.whitening.nsamples ...
                                                  - (wlen + 1)
            continue;
        end

        %if spike amplitude is below amp threshold, drop it
        if CBPdata.CBP.spike_amps{s}(n) < CBPdata.amplitude.amp_thresholds(s)
          continue;
        end

        snip_begin = round(CBPdata.CBP.spike_times{s}(n) - wlen);
        snip_end = round(CBPdata.CBP.spike_times{s}(n) + wlen);
        snippet = CBPdata.whitening.data(:, snip_begin:snip_end);

        X_CBP = [X_CBP reshape(snippet',[],1)];
        CBP_assignments = [CBP_assignments;s];
    end
end

XProj_CBP = X_CBP' * CBPdata.clustering.PCs;

CBPdata.clusteringcomparison = [];
CBPdata.clusteringcomparison.X_CBP = X_CBP;
CBPdata.clusteringcomparison.CBP_assignments = CBP_assignments;
CBPdata.clusteringcomparison.XProj_CBP = XProj_CBP;
