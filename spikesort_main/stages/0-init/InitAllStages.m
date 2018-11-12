function InitAllStages
global params dataobj cbpglobals;
% Run the setup function, which sets paths and prints warnings or errors if
% there are issues detected (for example, mex/C files that need to be compiled
% for your system).

fprintf('***Running initial setup...\n');

%=========================================
% Do basics and prepare for stage processing
SetupBasics;
FillInDefaultParameters;

cbpglobals.stages = {};
cbpglobals.currstagenum = 0;
cbpgloabls.currselected = 0;

%=========================================
% Preprocessing
RawDataStage = [];
RawDataStage.name = 'RawData';
RawDataStage.next = 'Filter';
RawDataStage.category = 'Preprocessing';
RawDataStage.description = 'Load raw electrode data';
RawDataStage.paramname = 'rawdata';

FilterStage = [];
FilterStage.name = 'Filter';
FilterStage.next = 'Whiten';
FilterStage.category = 'Preprocessing';
FilterStage.description = 'Temporal filtering';
FilterStage.paramname = 'filtering';

WhitenStage = [];
WhitenStage.name = 'Whiten';
WhitenStage.next = 'InitializeWaveform';
WhitenStage.category = 'Preprocessing';
WhitenStage.description = 'Estimate noise covariance and whiten data';
WhitenStage.paramname = 'whitening';

InitializeWaveformStage = [];
InitializeWaveformStage.name = 'InitializeWaveform';
InitializeWaveformStage.next = 'SpikeTiming';
InitializeWaveformStage.category = 'Preprocessing';
InitializeWaveformStage.description = 'Estimate initial spike waveforms';
InitializeWaveformStage.paramname = 'clustering';

RegisterStage(RawDataStage);
RegisterStage(FilterStage);
RegisterStage(WhitenStage);
RegisterStage(InitializeWaveformStage);

%=========================================
% CBP
SpikeTimingStage = [];
SpikeTimingStage.name = 'SpikeTiming';
SpikeTimingStage.next = 'AmplitudeThreshold';
SpikeTimingStage.category = 'CBP';
SpikeTimingStage.description = 'Use CBP to estimate spike times';
SpikeTimingStage.paramname = 'cbp';

AmplitudeThresholdStage = [];
AmplitudeThresholdStage.name = 'AmplitudeThreshold';
AmplitudeThresholdStage.next = 'ClusteringComparison';
AmplitudeThresholdStage.category = 'CBP';
AmplitudeThresholdStage.description = 'Identify spikes by thresholding amplitudes of each cell';
AmplitudeThresholdStage.paramname = 'amplitude';

ClusteringComparisonStage = [];
ClusteringComparisonStage.name = 'ClusteringComparison';
ClusteringComparisonStage.next = 'WaveformRefinement';
ClusteringComparisonStage.category = 'CBP';
ClusteringComparisonStage.description = 'PCA Comparison';
ClusteringComparisonStage.paramname = 'clustering';

WaveformRefinementStage = [];
WaveformRefinementStage.name = 'WaveformRefinement';
WaveformRefinementStage.next = 'SpikeTiming';
WaveformRefinementStage.category = 'CBP';
WaveformRefinementStage.description = 'Re-estimate waveforms';
WaveformRefinementStage.showreview = true;
WaveformRefinementStage.paramname = 'cbp';

RegisterStage(SpikeTimingStage);
RegisterStage(AmplitudeThresholdStage);
RegisterStage(ClusteringComparisonStage);
RegisterStage(WaveformRefinementStage);

%=========================================
% Post-Analysis
TimingComparisonStage = [];
TimingComparisonStage.name = 'TimingComparison';
TimingComparisonStage.next = 'MikeComparison';
TimingComparisonStage.category = 'Post-Analysis';
TimingComparisonStage.description = 'Timing Comparison';
TimingComparisonStage.paramname = 'postproc';

MikeComparisonStage = [];
MikeComparisonStage.name = 'MikeComparison';
MikeComparisonStage.next = 'Sonification';
MikeComparisonStage.category = 'Post-Analysis';
MikeComparisonStage.description = 'Mike Comparison';
MikeComparisonStage.paramname = 'postproc';

SonificationStage = [];
SonificationStage.name = 'Sonification';
SonificationStage.next = 'GreedySpike';
SonificationStage.category = 'Post-Analysis';
SonificationStage.description = 'Sonification';
SonificationStage.paramname = 'postproc';

GreedySpikeStage = [];
GreedySpikeStage.name = 'GreedySpike';
GreedySpikeStage.next = '';
GreedySpikeStage.category = 'Post-Analysis';
GreedySpikeStage.description = 'Greedy Spike Comparison';
GreedySpikeStage.paramname = 'postproc';

RegisterStage(TimingComparisonStage);
RegisterStage(MikeComparisonStage);
RegisterStage(SonificationStage);
RegisterStage(GreedySpikeStage);

fprintf('***Done initialization.\n\n');
CBPNext;
