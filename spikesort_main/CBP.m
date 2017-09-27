<<<<<<< HEAD
%===============================================================
% This is the main CBP script.
% You can send in the input parameters that you want by setting the
% "params" object beforehand.
% To set the filename you want, put that in params.general.filename.

global params dataobj;

%%Establish path
addpath(genpath(pwd));

%%Begin script. The stages proceed linearly from here
InitStage;

%%%%Stages are, in order%%%%
%%Pre-processing
%RawDataStage;
%FilterStage;
%WhitenStage;
%InitializeWaveformStage;

%%CBP
%CBPSetupStage;
%SpikeTimingStage;
%MatchWaveformStage;
%WaveformReestimationStage; (%%want to return back to a previous stage)

%%%%Stop here for now%%%%%
%%To add in the future - Post-analysis
% PostAnalysisComparisonStage();
% PlotSubpopulationStage();
% PlotPCAStage();
% PlotGreedySpikesStage();
=======
%===============================================================
% This is the main CBP script.
% You can send in the input parameters that you want by setting the
% "params" object beforehand.
% To set the filename you want, put that in params.general.filename.

global params dataobj;

%%Establish path
addpath(genpath(pwd));

%%Begin script
InitStage;

%%%%Stages are, in order%%%%
%%Pre-processing
%RawDataStage;
%FilterStage;
%WhitenStage;
%InitializeWaveformStage;

%%CBP
%CBPSetupStage;
%SpikeTimingStage;
%MatchWaveformStage;
%WaveformReestimationStage; (%%want to return back to a previous stage)

%%%%Stop here for now%%%%%
%%To add in the future - Post-analysis
% PostAnalysisComparisonStage();
% PlotSubpopulationStage();
% PlotPCAStage();
% PlotGreedySpikesStage();
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
