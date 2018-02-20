function InitStage
global params dataobj stages currstageind;
% Run the setup function, which sets paths and prints warnings or errors if
% there are issues detected (for example, mex/C files that need to be compiled
% for your system).

fprintf('***Running initial setup...\n');

%Preprocessing
stages = {};
currstageind = 0;
RegisterStage(@RawDataStage,@FilterStage,@RawDataPlot);
RegisterStage(@FilterStage,@WhitenStage,@FilterPlot);
RegisterStage(@WhitenStage,@InitializeWaveformStage,@WhitenPlot);
RegisterStage(@InitializeWaveformStage,@SpikeTimingStage,@InitializeWaveformPlot);

%CBP
RegisterStage(@SpikeTimingStage,@AmplitudeThresholdStage,@SpikeTimingPlot);
RegisterStage(@AmplitudeThresholdStage,@WaveformReestimationStage,@AmplitudeThresholdPlot);
RegisterStage(@WaveformReestimationStage,@SpikeTimingStage,@WaveformReestimationPlot);

%Post-analysis
RegisterStage(@SonificationStage,@SonificationStage,[]);

SetupBasics;
FillInDefaultParameters;

fprintf('***Done initialization.\n\n');
RawDataStage;