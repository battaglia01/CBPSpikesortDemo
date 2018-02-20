%===============================================================
% CBP(filename, params) - work in progress

global params dataobj;

%%Establish path
addpath(genpath(pwd));

%%Begin script
InitStage;

%%%%Stages are, in order%%%%
%%Pre-processing
RawDataStage;
FilterStage;
WhitenStage;
InitializeWaveformStage;

%%CBP
CBPSetupStage;
SpikeTimingStage;
AmplitudeThresholdStage;
WaveformReestimationStage;

%%%%Stop here for now%%%%%
%%To add in the future - Post-analysis
% PostAnalysisComparisonStage();
% PlotSubpopulationStage();
% PlotPCAStage();
% PlotGreedySpikesStage();
