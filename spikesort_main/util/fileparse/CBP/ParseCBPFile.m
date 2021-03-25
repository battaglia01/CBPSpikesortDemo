% Parses a CBP formatted .mat file and puts the data in the global
% CBPdata and params. Return false if there are any problems.
%
% Data are assumed to be in a matlab (.mat) file, containing the following
% arrays as sub-objects:
%   CBPdata.raw_data.data: channel x time matrix of voltage traces
%   CBPdata.raw_data.dt : the temporal sampling interval (in seconds)
% The file may optionally also contain:
%   CBPdata.ground_truth.true_spike_times : vector of ground truth spike times,
%       if known
%   CBPdata.ground_truth.true_spike_class : vector of numerical cell labels for
%       each time
% If a filename is entered, it should be a .mat file with at least
%   "CBPdata.raw_data.data" and "CBPdata.raw_data.dt" in it.
% dt is the reciprocal of sample rate, and data is a
% matrix in which each row represents one electrode.

function result = ParseCBPFile(filename)
    global CBPdata params CBPInternals;
    load(filename);

    % Make sure the necessary matrices exist
    assert(logical(exist('CBPdata')), "File must have CBPdata object!");
    assert(isfield(CBPdata, 'raw_data'), "File must have CBPdata.raw_data object!");
    assert(isfield(CBPdata.raw_data, 'data'), "File must have CBPdata.raw_data.data defined!");
    assert(isfield(CBPdata.raw_data, 'dt'), "File must have CBPdata.raw_data.dt defined!");

    result = true;
end
