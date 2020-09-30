% This function removes clusters by simply deleting them and removing all of
% the cluster spike times. It is recommended that this step be performed
% last, as subsequent cluster operations may "rediscover" these cluster in
% the data.
function RemoveClusters(waveform_inds)
global CBPdata params CBPInternals;

CL = CBPdata.clustering;

% Check to make sure we have valid clusters
assert(all(ismember(waveform_inds, 1:params.clustering.num_waveforms)), ...
       ['Invalid clusters! Are you sure you entered a space-delimited list, ' ...
       'from clusters 1 to ' num2str(params.clustering.num_waveforms) '?']);

% remove assignments and segment centers
to_remove_mask = ismember(CL.assignments, waveform_inds);
CL.assignments(to_remove_mask) = [];
CL.segment_centers(to_remove_mask) = [];

% redo assignment numbers
next_num = 1;
for n=1:max(CL.assignments)
    assignment_inds = find(CL.assignments == n);
    if ~isempty(assignment_inds)
        CL.assignments(assignment_inds) = next_num;
        next_num = next_num + 1;
    end
end

% change num_waveforms params
params.clustering.num_waveforms = ...
       params.clustering.num_waveforms - (length(waveform_inds));

% remove centroids
CL.centroids(:, waveform_inds) = [];

% do PCs, X, and X Proj
CL.X(:, to_remove_mask) = [];
[CL.PCs, CL.XProj] = TruncatePCs(CL.X, params.clustering.percent_variance);

% do init_waveforms and spike_time_array_cl
CL.init_waveforms(waveform_inds) = [];
CL.spike_time_array_cl(waveform_inds) = [];

% set CBPdata.clustering back 
CBPdata.clustering = CL;

% reset number of passes
CBPdata.CBP.num_passes = 0;

% Lastly, clear stale tabs and replot:
if (params.plotting.calibration_mode)
    clusteringstage = GetStageFromName('InitializeWaveform');
    ClearStaleTabs(clusteringstage.next);
    InitializeWaveformPlot;
    ChangeCalibrationTab('Initial Waveforms, Shapes');
end
