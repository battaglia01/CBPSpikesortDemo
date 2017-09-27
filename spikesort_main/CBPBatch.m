<<<<<<< HEAD
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
MatchWaveformStage;
WaveformReestimationStage;

%%%%Stop here for now%%%%%
%%To add in the future - Post-analysis
% PostAnalysisComparisonStage();
% PlotSubpopulationStage();
% PlotPCAStage();
% PlotGreedySpikesStage();
=======
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
MatchWaveformStage;
WaveformReestimationStage;

%%%%Stop here for now%%%%%
%%To add in the future - Post-analysis
% PostAnalysisComparisonStage();
% PlotSubpopulationStage();
% PlotPCAStage();
% PlotGreedySpikesStage();
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
