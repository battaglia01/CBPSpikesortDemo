%===============================================================
% CBPBatch(num_iterations)
% Runs CBP in non-diagnostic mode.
% This runs CBP `num_iterations` times, with each successive iteration
% using the results of the previous iteration as a starting point.
%
% This will clear the workspace and prompt you to import a file.
%
% Usage: CBPBatch(num_iterations)

function CBPBatch(num_iterations)
% set up globals (even in base workspace) and path
global CBPdata params CBPInternals;
evalin('base','global CBPdata params');
addpath(genpath(pwd));
[curpath, ~, ~] = fileparts(mfilename('fullpath') + ".m");
addpath(genpath(curpath));

% If there's an existing session, ask before overwriting and beginning anew
answer = questdlg("Welcome to CBP (Batch mode). " + ...
                  "If you have any CBP data already loaded into the " + ...
                  "workspace, this will clear it and begin a new " + ...
                  "session. Are you sure you want to clear existing "+ ...
                  "data and begin?", ...
                  "Batch Session", "Yes", "No", "No");
if answer == "Yes"
    CBPReset;
else
    return;
end

% Add all subdirectories of this one to the path, and init everything
BasicSetup;

% Open import file dialog, only proceed if the user doesn't choose cancel
result = ImportFileDialog;
if ~result % returns true if user didn't cancel
    return;
end
clear result;

% If no iterations are specified, assume 1
if nargin == 0
    num_iterations=1;
end

% Set calibration mode off
params.plotting.calibration_mode=0;

%%%%stages are, in order%%%%
% Pre-processing
CBPStage('RawData');
CBPStage('Filter');
CBPStage('Whiten')
CBPStage('InitializeWaveform');

% CBP
for n=1:num_iterations
    CBPStage('SpikeTiming');
    CBPStage('AmplitudeThreshold');
    CBPStage('ClusteringComparison');
    CBPStage('WaveformRefinement');
end

% Post-analysis
params.plotting.calibration_mode=1;
CBPStage('TimingComparison');

%% The user will pick the next stages on their own, but listed for reference...
%CBPStage('Sonification');
%CBPStage('GreedySpike');
