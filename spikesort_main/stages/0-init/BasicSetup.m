% This is the "Basic Setup" stage.
%
% This stage is for those things that need to be set up before the file is
% even loaded (paths, parallel pool, registering stages, etc).

function BasicSetup
global CBPdata params CBPInternals;
% Run the setup function, which sets paths and prints warnings or errors if
% there are issues detected (for example, mex/C files that need to be compiled
% for your system).

fprintf('*** Running initial setup...\n');

%=========================================
% Do basics and prepare for stage processing

% Clear all figures
close all;

% Create parallel pool
fprintf('   Launching parallel pool. Depending on your setup, this may take a minute...\n');
if (exist('parpool')==2)
  try
    if (isempty(gcp('nocreate')))
      parpool
    end
  catch me
    warning('Failed to open parallel pool using parpool:\n  %s\n',...
        me.message);
  end
end

% Check that MEX files are compiled (the following lines will print
% warnings if not).
[~, ~] = greedymatchtimes([], [], [], []);
[~, ~] = trialevents([], [], [], []);
ecos(1, sparse(1), 1, struct('l', 1, 'q', []), struct('verbose', 0))

% Initialize "CBPInternals" global variable
CBPInternals.stages = {};
CBPInternals.raninit = true;
CBPInternals.mostrecentstage = [];
CBPInternals.currselectedtabstage = [];
CBPInternals.originalLnF = javax.swing.UIManager.getLookAndFeel;
CBPInternals.cells_to_plot = 1:9;   % default clusters to plot, can be changed

% Register file formats
%%@ NOTE - these must be chars, not strings, due to bug in MATLAB's
%%@ uiputfile. Although we sanitize anyway
% ** import
RegisterFileFormat('*.mat', 'CBP file', @ParseCBPFile, 'import');
RegisterFileFormat('*.prm', 'Klusta file', @ParseKlustaFile, 'import');
RegisterFileFormat('*.xml', 'Neuroscope/Klusters file', @ParseNeuroscopeFile, 'import');
RegisterFileFormat('*.dat', 'Raw DAT file', @ParseRawDataFile, 'import');

% ** export
RegisterFileFormat('*.mat', 'CBP file', @ExportCBPFile, 'export');
RegisterFileFormat('*.npy', 'Phy file', @ExportPhyFile, 'export');
RegisterFileFormat('*.mda', 'MDA file', @ExportMDAFile, 'export');

%=========================================
% Preprocessing
RawDataStage = StageObject;
RawDataStage.name = 'RawData';
RawDataStage.next = 'Filter';
RawDataStage.category = 'Preprocessing';
RawDataStage.description = 'Load raw electrode data';
RawDataStage.paramname = 'general';

FilterStage = StageObject;
FilterStage.name = 'Filter';
FilterStage.next = 'Whiten';
FilterStage.category = 'Preprocessing';
FilterStage.description = 'Temporal filtering';
FilterStage.paramname = 'filtering';

WhitenStage = StageObject;
WhitenStage.name = 'Whiten';
WhitenStage.next = 'InitializeWaveform';
WhitenStage.category = 'Preprocessing';
WhitenStage.description = 'Estimate noise covariance and whiten data';
WhitenStage.paramname = 'whitening';

InitializeWaveformStage = StageObject;
InitializeWaveformStage.name = 'InitializeWaveform';
InitializeWaveformStage.next = 'SpikeTiming';
InitializeWaveformStage.category = 'Preprocessing';
InitializeWaveformStage.description = 'Estimate initial spike waveforms';
InitializeWaveformStage.paramname = 'clustering';
InitializeWaveformStage.replotoncellchange = true;

RegisterStage(RawDataStage);
RegisterStage(FilterStage);
RegisterStage(WhitenStage);
RegisterStage(InitializeWaveformStage);

%=========================================
% CBP
SpikeTimingStage = StageObject;
SpikeTimingStage.name = 'SpikeTiming';
SpikeTimingStage.next = 'AmplitudeThreshold';
SpikeTimingStage.category = 'CBP';
SpikeTimingStage.description = 'Use CBP to estimate spike times';
SpikeTimingStage.paramname = 'cbp';
SpikeTimingStage.replotoncellchange = true;

AmplitudeThresholdStage = StageObject;
AmplitudeThresholdStage.name = 'AmplitudeThreshold';
AmplitudeThresholdStage.next = 'ClusteringComparison';
AmplitudeThresholdStage.category = 'CBP';
AmplitudeThresholdStage.description = 'Identify spikes by thresholding amplitudes of each cell';
AmplitudeThresholdStage.paramname = 'amplitude';
AmplitudeThresholdStage.replotoncellchange = true;

ClusteringComparisonStage = StageObject;
ClusteringComparisonStage.name = 'ClusteringComparison';
ClusteringComparisonStage.next = 'WaveformRefinement';
ClusteringComparisonStage.category = 'CBP';
ClusteringComparisonStage.description = 'PCA Comparison';
ClusteringComparisonStage.paramname = 'clustering';
ClusteringComparisonStage.replotoncellchange = true;

WaveformRefinementStage = StageObject;
WaveformRefinementStage.name = 'WaveformRefinement';
WaveformRefinementStage.next = 'SpikeTiming';
WaveformRefinementStage.category = 'CBP';
WaveformRefinementStage.description = 'Re-estimate waveforms';
WaveformRefinementStage.showreview = true;
WaveformRefinementStage.paramname = 'cbp';
WaveformRefinementStage.replotoncellchange = true;

RegisterStage(SpikeTimingStage);
RegisterStage(AmplitudeThresholdStage);
RegisterStage(ClusteringComparisonStage);
RegisterStage(WaveformRefinementStage);

%=========================================
% Post-Analysis
TimingComparisonStage = StageObject;
TimingComparisonStage.name = 'TimingComparison';
TimingComparisonStage.next = 'Sonification';
TimingComparisonStage.category = 'Post-Analysis';
TimingComparisonStage.description = 'Timing Comparison';
TimingComparisonStage.paramname = 'postproc';
TimingComparisonStage.replotoncellchange = true;

SonificationStage = StageObject;
SonificationStage.name = 'Sonification';
SonificationStage.next = 'GreedySpike';
SonificationStage.category = 'Post-Analysis';
SonificationStage.description = 'Sonification';
SonificationStage.paramname = 'postproc';

GreedySpikeStage = StageObject;
GreedySpikeStage.name = 'GreedySpike';
GreedySpikeStage.next = '';
GreedySpikeStage.category = 'Post-Analysis';
GreedySpikeStage.description = 'Greedy Spike Comparison';
GreedySpikeStage.paramname = 'postproc';

RegisterStage(TimingComparisonStage);
RegisterStage(SonificationStage);
RegisterStage(GreedySpikeStage);

fprintf('*** Done initialization.\n\n');
