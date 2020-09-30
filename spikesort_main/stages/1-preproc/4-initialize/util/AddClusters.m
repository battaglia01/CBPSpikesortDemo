% This function "adds" new clusters to the existing set without splitting
% an existing cluster. It removes all existing clusters from the signal,
% using the cluster centroids and estimated times, to obtain an estimated
% residue, and then reclusters the residue
%%@ NOTE: this is basically the same as adding a new blank "dummy"
%%@ waveform, then "reassessing" that waveform, which is what we'll do

function AddClusters(num_new)
global CBPdata params CBPInternals;

CL = CBPdata.clustering;

% in case reassessing crashes, save the old one
CLold = CBPdata.clustering;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check to make sure we have entered a valid number of new waveforms
assert(num_new > 0, ...
        'Invalid entry! Please enter a number of new clusters greater than 0!');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now create some new "dummy" waveforms
num_waveforms = size(CL.centroids, 2);
CL.centroids(:, num_waveforms+(1:num_new)) = 0;
CL.init_waveforms(end+(1:num_new)) = ...
    {zeros(size(CL.init_waveforms{1}))};
CL.spike_time_array_cl(end+(1:num_new)) = {[]};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% store in CBPdata and change param, and reset number of passes
old_num_waveforms = params.clustering.num_waveforms;
CBPdata.clustering = CL;
params.clustering.num_waveforms = length(CL.init_waveforms);
CBPdata.CBP.num_passes = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now "reassess"
try
    ReassessClusters(old_num_waveforms + (1:num_new));
catch err
    % if this doesn't go right, put things back the way they were
    CBPdata.clustering = CLold;
    rethrow(err);
end

% normally we'd re-match the waveforms and re-plot, but
% ReassessClusters already does that, so we exit