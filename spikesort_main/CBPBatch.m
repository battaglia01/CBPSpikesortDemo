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
InitAllStages;

%%%%stages are, in order%%%%
%%Pre-processing
CBPStage('RawData');
CBPStage('Filter');
CBPStage('Whiten')
CBPStage('InitializeWaveform');

%%CBP
for n=1:num_iterations
    CBPStage('SpikeTiming');
    CBPStage('AmplitudeThreshold');
    CBPStage('WaveformRefinement');
end

%%Post-analysis
params.general.calibration_mode=1;
CBPStage('TimingComparison');
CBPStage('ClusteringComparison');
CBPStage('Sonification');
CBPStage('GreedySpike');
