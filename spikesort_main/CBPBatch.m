%===============================================================
% CBPBatch(num_iterations)
% Runs CBP in non-diagnostic mode.
% This runs CBP `num_iterations` times, with each successive iteration
% using the results of the previous iteration as a starting point.

function CBPBatch(num_iterations)
global params dataobj;

%%Establish path
addpath(genpath(pwd));

if nargin == 0
    num_iterations=1;
end


%%Set calibration mode off
params.general.calibration_mode=0;

%%Begin script
InitStage;

%%%%stages are, in order%%%%
%%Pre-processing
RawDataStage;
FilterStage;
WhitenStage;
InitializeWaveformStage;

%%CBP
for n=1:num_iterations
    SpikeTimingStage;
    AmplitudeThresholdStage;
    WaveformReestimationStage;
end

%%%%Stop here for now%%%%%
%%For Reference - Post-analysis below
% PostAnalysisComparisonStage();
% PlotSubpopulationStage();
% PlotPCAStage();
% PlotGreedySpikesStage();
