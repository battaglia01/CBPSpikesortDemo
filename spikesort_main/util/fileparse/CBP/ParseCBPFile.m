% Parses a CBP formatted .mat file and puts the data in the global
% CBPdata and params. Return false if there are any problems.
%
% Data are assumed to be in a matlab (.mat) file, containing:
%   data: channel x time matrix of voltage traces
%   dt : the temporal sampling interval (in seconds)
% The file may optionally also contain:
%   true_spike_times : vector of ground truth spike times, if known
%   true_spike_class : vector of numerical cell labels for each time
% If a filename is entered, it should be a .mat file with at least "data"
% and "dt" loaded. dt is the reciprocal of sample rate, and data is a
% matrix in which each row represents one electrode.

function result = ParseCBPFile(filename)
    global CBPdata params CBPInternals;
    load(filename);
    
    assert(logical(exist('CBPdata')), "File must have CBPdata object!");
    assert(isfield(CBPdata, 'rawdata'), "File must have CBPdata.rawdata object!");
    assert(isfield(CBPdata.rawdata, 'data'), "File must have CBPdata.rawdata.data defined!");
    assert(isfield(CBPdata.rawdata, 'dt'), "File must have CBPdata.rawdata.dt defined!");
    
    result = true;
end