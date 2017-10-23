%==========================================================================
% Step 1: Load raw electrode data
% Load an example data set, including raw data, the timestep, and
% (optionally) ground truth spike times.
%
% Calibration for raw data loading:
%   Fig 1a shows the raw data.
%   Fig 2a plots the Fourier amplitude (averaged across channels).

function RawDataStage
global params dataobj;

fprintf('***Preprocessing step 1: Loading raw electrode data...\n');

try
    datasetName = params.general.filename;
catch
    fprintf('No filename detected in params.general.filename\n');
    fprintf('  Please enter filename below, or for demo data sets,\n');
    fprintf('  type in ''Quiroga1'' or ''Harris1''\n');
    fprintf('  If you already have ''data'' and ''dt'' variables\n');
    fprintf('  loaded in the workspace, type ''workspace''\n\n');
    datasetName = input('Enter dataset: ','s');
    % Pick one data set below by uncommenting the assignment to datasetName:

    % Simulated data example: Single electrode, from: Quiroga et. al., Neural
    % Computation, 16:1661-1687, 2004
    % datasetName = 'Quiroga1';

    % Real data example: Tetrode + one ground-truth intracellular electrode, rat
    % hippocampus, from: Harris et. al., J. Neurophysiology, 84:401-414, 2000
    % datasetName = 'Harris1';
end

dataobj.rawdata = LoadRawData(datasetName);
if (params.general.calibration_mode)
    PlotRawData(dataobj.rawdata);
end

fprintf('***Done preprocessing step 1.\n\n');
CBPNext('FilterStage');
