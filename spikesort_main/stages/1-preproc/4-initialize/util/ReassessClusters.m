% This function "removes" all of the other cluster waveforms from the
% signal except the given indices, and then re-clusters the residue. This
% can be helpful if one of the clusters seems to be noise, or interfered
% with by the other waveforms.

function ReassessClusters(waveform_inds, do_plot)
global CBPdata params CBPInternals;

if nargin < 2
    do_plot = true;
end

CL = CBPdata.clustering;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have valid waveform indices
assert(min(waveform_inds) >= 1 && ...
       max(waveform_inds) <= params.clustering.num_waveforms, ...
      ['Invalid clusters! Are you sure you entered a space-delimited list, ' ...
       'from clusters 1 to ' num2str(params.clustering.num_waveforms) '?']);

% this fixes some indexing issues further down
waveform_inds = sort(waveform_inds);

% merge waveforms and delete old indices
old_inds = setdiff(1:length(CL.init_waveforms), waveform_inds);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate combined traces from the old inds to remove, then get residue
amps = {};
for n=1:length(old_inds)
    amps{n} = ones(size(CL.spike_time_array_cl{old_inds(n)}));
end
all_traces = CreateSpikeTraces(CL.spike_time_array_cl(old_inds), ...
                               amps, ...
                               CL.init_waveforms(old_inds), ...
                               CBPdata.whitening.nsamples, ...
                               CBPdata.whitening.nchan);
mixed_trace = 0;
for n=1:length(all_traces)
    mixed_trace = mixed_trace + all_traces{n}';
end
trace_residue = CBPdata.whitening.data - mixed_trace;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now initialize again on the residue
tmp_cluster_pars = params.clustering;
tmp_cluster_pars.num_waveforms = length(waveform_inds);
[new_centroids, new_assignments, ...
 new_X, new_XProj, new_PCs, ...
 new_segment_centers, ...
 new_init_waveforms, ...
 new_spike_time_array_cl] = ...
    EstimateInitialWaveforms(trace_residue, ...
                             CBPdata.whitening.nchan, ...
                             params.general.spike_waveform_len, ...
                             tmp_cluster_pars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now merge new clustering data into old clustering data
% do centroids and init_waveforms
for n=1:length(waveform_inds)
    CL.centroids(:, waveform_inds(n)) = new_centroids(:, n);
    CL.init_waveforms{waveform_inds(n)} = new_init_waveforms{n};
end

% do segment_centers
old_assignment_mask = ~ismember(CL.assignments, waveform_inds);
segment_centers = ...
    [CL.segment_centers(old_assignment_mask); new_segment_centers];
[CL.segment_centers, sortidx] = sort(segment_centers);

% do assignments - running the loop backwards prevents certain issues
% updating indices and accidentally matching existing indices
for n=length(waveform_inds):-1:1
    new_assignments(new_assignments == n) = waveform_inds(n);
end
assignments = [CL.assignments(old_assignment_mask); new_assignments];
assignments = assignments(sortidx);
CL.assignments = assignments;

% do X
X = [CL.X(:, old_assignment_mask) new_X];
X = X(:, sortidx);
CL.X = X;

% do PCs
[CL.PCs, CL.XProj] = TruncatePCs(CL.X, params.clustering.percent_variance);

% do spike_time_array_cl
CL.spike_time_array_cl = ...
    GetSpikeTimeCellArrayFromVectors(CL.segment_centers, CL.assignments);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% store in CBPdata
CBPdata.clustering = CL;

% reset number of passes
CBPdata.CBP.num_passes = 0;

% Lastly, clear stale tabs and replot:
if params.plotting.calibration_mode && do_plot
    clusteringstage = GetStageFromName('InitializeWaveform');
    ClearStaleTabs(clusteringstage.next);
    InitializeWaveformPlot;
    ChangeCalibrationTab('Initial Waveforms, Shapes');
end
