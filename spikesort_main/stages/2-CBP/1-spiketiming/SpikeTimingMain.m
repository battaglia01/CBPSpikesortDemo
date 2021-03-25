%% -----------------------------------------------------------------------------
% CBP step 1: use CBP to estimate spike times
%   This takes the previous CBPdata.CBP.final_waveforms, and initializes
%     the next CBPdata.CBP.init_waveforms with it.
%   If this is the first runthrough, we instead use
%     CBPdata.clustering.init_waveforms.
%   The new CBPdata.CBP.final_waveforms is set in the
%     WaveformRefinementStage, after we have processed Amplitudes and so
%     on.
function SpikeTimingMain
global CBPdata params CBPInternals;

% set up CBPdata.CBP, init_waveforms
if CBPdata.CBP.num_passes == 0 || ...
        ~isfield(CBPdata, 'waveform_refinement') || ...
        ~isfield(CBPdata.waveform_refinement, 'final_waveforms')
    % if CBP num_passes == 0, or if we haven't gotten all the way to
    % waveform refinement, initialize with clustering
    first_pass = true;
    fprintf('*** Using initial estimates as CBP starting point...\n');
    CBPdata.CBP.init_waveforms = CBPdata.clustering.init_waveforms;
    CBPdata.CBP.num_waveforms = params.clustering.num_waveforms;
else
    % else, use the last (thresholded) waveforms as initial waveforms for this
    % CBP round
    first_pass = false;
    fprintf('*** Seeding new initial waveforms with previous final waveforms...\n');
    CBPdata.CBP.init_waveforms = CBPdata.waveform_refinement.final_waveforms;
    CBPdata.CBP.num_waveforms = CBPdata.waveform_refinement.num_waveforms;
end

% Partition the signal into snippets
[CBPdata.CBP.snippets, CBPdata.CBP.breaks, ...
    CBPdata.CBP.snippet_lens, CBPdata.CBP.snippet_centers, ...
    CBPdata.CBP.snippet_idx] = ...
        PartitionSignal(CBPdata.whitening.data, params.partition);

% Get spike times
[CBPdata.CBP.spike_time_array, CBPdata.CBP.spike_time_array_ms, ...
    CBPdata.CBP.spike_amps, CBPdata.CBP.recon_snippets] = ...
        SpikesortCBP(CBPdata.CBP.snippets, CBPdata.CBP.snippet_centers, ...
                     CBPdata.CBP.init_waveforms, params.cbp_outer, ...
                     params.cbp, CBPdata.whitening.dt);

% Create spike traces
CBPdata.CBP.spike_traces_init = ...
    CreateSpikeTraces(CBPdata.CBP.spike_time_array, ...
                      CBPdata.CBP.spike_amps, ...
                      CBPdata.CBP.init_waveforms, ...
                      CBPdata.whitening.nsamples, ...
                      CBPdata.whitening.nchan);

% Develop single vectors of (rounded) sample times and assignments
[CBPdata.CBP.segment_centers, CBPdata.CBP.assignments] = ...
    GetSpikeVectorsFromTimeCellArray(CBPdata.CBP.spike_time_array);

% add PCs and so on
[CBPdata.CBP.X, ~, CBPdata.CBP.assignments, CBPdata.CBP.PCs, ...
 CBPdata.CBP.XProj, ~, ~] = ...
    GetAllSpikeInfo(...
        CBPdata.CBP.segment_centers, CBPdata.CBP.assignments);

% now that we've finished, update num_passes
if first_pass
    % first pass, so just set it to 1
    CBPdata.CBP.num_passes = 1;
else
    % not first pass - increment the last waveform refinement pass
    CBPdata.CBP.num_passes = CBPdata.waveform_refinement.num_passes + 1;
end

% get rid of the old, previous amplitude thresholding, clustering comparison,
% etc, as it's all stale now
if isfield(CBPdata, 'amplitude')
    CBPdata = rmfield(CBPdata, 'amplitude');
end
if isfield(CBPdata, 'clusteringcomparison')
    CBPdata = rmfield(CBPdata, 'clusteringcomparison');
end
if isfield(CBPdata, 'waveform_refinement')
    CBPdata = rmfield(CBPdata, 'waveform_refinement');
end
