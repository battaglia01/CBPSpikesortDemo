%==========================================================================
%%@ FIXME - CHANGE THIS FOR NEW FORMAT
% Step 1: Load raw electrode data
% Load an example data set, including raw data, the timestep, and
% (optionally) ground truth spike times.
%
% Load raw electrode data from a file, and adjust any parameters
% that need to be specialized for that data set.

function RawDataMain
global CBPdata params CBPInternals;
    % All work is now done in ImportFileDialog, which is called in CBPBegin.m
    % This is split off from the main RawDataStage so we can:
    % 1. Call it in batch processing
    % 2. Let the user cancel in the GUI if they don't want CBP
    % As a result, this function is just for plotting now.
end
