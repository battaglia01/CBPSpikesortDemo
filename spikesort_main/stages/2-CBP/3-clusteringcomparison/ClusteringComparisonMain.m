%% ----------------------------------------------------------------------------------
% Post-analysis: Comparison of CBP to clustering results, and to ground truth (if
% available)

function ClusteringComparisonMain
global params dataobj;

% First, assemble a "snippet" matrix from the CBP spike times, as well as
% a tag for which spike it came from

[X_CBP, CBP_assignments, XProj_CBP] = GetCBPSnippets;

dataobj.clusteringcomparison = [];
dataobj.clusteringcomparison.X_CBP = X_CBP;
dataobj.clusteringcomparison.CBP_assignments = CBP_assignments;
dataobj.clusteringcomparison.XProj_CBP = XProj_CBP;
