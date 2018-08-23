%% ----------------------------------------------------------------------------------
% Post-analysis: Comparison of CBP to clustering results, and to ground truth (if
% available)

%** indicate which cells match ground truth.

function GreedySpikeStage
global params dataobj;
UpdateStage(@GreedySpikeStage);

fprintf('***Postprocessing Step 5: Greedy Spike Comparison\n'); %%@New

%% ----------------------------------------------------------------------------------
% Get greedy spike matches and plot RoC-style
% NB: Much faster if mex greedymatchtimes.c is compiled
%*** show chosen threshold in top plot
%*** also show log # spikes found?
    
if (params.general.calibration_mode)
    GreedySpikePlot;
end


fprintf('***Done postprocessing step 5!\n\n');
StageInstructions;
