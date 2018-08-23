function InitStage
global params dataobj cbpglobals;
% Run the setup function, which sets paths and prints warnings or errors if
% there are issues detected (for example, mex/C files that need to be compiled
% for your system).

fprintf('***Running initial setup...\n');

%Preprocessing
cbpglobals.stages = {};
cbpglobals.currstageind = 0;
RegisterStage(@RawDataStage,@FilterStage,@RawDataPlot,'Preprocessing');
RegisterStage(@FilterStage,@WhitenStage,@FilterPlot,'Preprocessing');
RegisterStage(@WhitenStage,@InitializeWaveformStage,@WhitenPlot,'Preprocessing');
RegisterStage(@InitializeWaveformStage,@SpikeTimingStage,@InitializeWaveformPlot,'Preprocessing');

%CBP
RegisterStage(@SpikeTimingStage,@AmplitudeThresholdStage,@SpikeTimingPlot,'CBP');
RegisterStage(@AmplitudeThresholdStage,@WaveformReestimationStage,@AmplitudeThresholdPlot,'CBP');
RegisterStage(@WaveformReestimationStage,@SpikeTimingStage,@WaveformReestimationPlot,'CBP');

%Post-analysis
RegisterStage(@SonificationStage,@SubpopulationStage,@SonificationPlot,'Post-Analysis');
RegisterStage(@SubpopulationStage,@PCAComparisonStage,@SubpopulationPlot,'Post-Analysis');
RegisterStage(@PCAComparisonStage,@GreedySpikeStage,@PCAComparisonPlot,'Post-Analysis');
RegisterStage(@GreedySpikeStage,@GreedySpikeStage,@GreedySpikePlot,'Post-Analysis');

SetupBasics;
FillInDefaultParameters;

fprintf('***Done initialization.\n\n');
RawDataStage;
