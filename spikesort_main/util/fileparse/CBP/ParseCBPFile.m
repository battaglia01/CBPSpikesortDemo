% Parses a CBP formatted .mat file and puts the data in the global
% CBPdata and params. Return false if there are any problems.
%
% Data are assumed to be in a matlab (.mat) file, containing the following
% arrays as sub-objects:
%   CBPdata.rawdata.data: channel x time matrix of voltage traces
%   CBPdata.rawdata.dt : the temporal sampling interval (in seconds)
% The file may optionally also contain:
%   CBPdata.groundtruth.true_spike_times : vector of ground truth spike times,
%       if known
%   CBPdata.groundtruth.true_spike_class : vector of numerical cell labels for
%       each time
% If a filename is entered, it should be a .mat file with at least
%   "CBPdata.rawdata.data" and "CBPdata.rawdata.dt" in it.
% dt is the reciprocal of sample rate, and data is a
% matrix in which each row represents one electrode.

function result = ParseCBPFile(filename)
    global CBPdata params CBPInternals;
    load(filename);

    % Make sure the necessary matrices exist
    assert(logical(exist('CBPdata')), "File must have CBPdata object!");
    assert(isfield(CBPdata, 'rawdata'), "File must have CBPdata.rawdata object!");
    assert(isfield(CBPdata.rawdata, 'data'), "File must have CBPdata.rawdata.data defined!");
    assert(isfield(CBPdata.rawdata, 'dt'), "File must have CBPdata.rawdata.dt defined!");

    result = true;
end
