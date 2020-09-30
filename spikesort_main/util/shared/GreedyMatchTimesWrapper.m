% This function is a wrapper for the MEX greedymatchtimes function.
% This function takes as input, two vectors of spike times, called `t1` and `t2`
% below. Typically, one will be an estimated spike time array, and one will be
% a ground truth spike time array. It then attempts to match spikes in one array
% with spikes in the other. A spike in one array is considered to match a spike
% in the other if the time distance is shorter than some maximum admissible
% distance `d`, the third parameter to the function.
%
% After internally merging the two arrays into a master array of spike times,
% merging any that are within the maximum distance, it makes two output vectors,
% called `m1` and `m2`. For merged spike `n`, the entry m1(n) is the index in t1
% corresponding to that merged spike, and the entry m2(n) is the correpsonding
% index in t2. If there's ever an `n` such that m1(n) is 0 and m2(n) is nonzero,
% that's a spike that's only in m1 with no corresponding match in m2 (so a false
% positive, if m1 is the estimated spike vector and m2 is ground truth).
% Likewise, if m1(n) is 0 and m2(n) is nonzero, that's a false negative. If
% both entries are 1, the spikes were both matched. There should never be any
% `n` such both entries are 0, or else there would not be a merged spike to
% compare to the original arrays to begin with.
%
% This function can also accept a cell array of vectors for t1 and t2, and it
% will then compare t1{1} and t2{1}, t1{2} and t2{2}, etc, and return the
% two m1 and m2 results as cell arrays. If t1 and t2 are arrays, then
% the maximum distance `d` must be a vector such that the n'th entry is the
% maximum distance when matching for t1{n} and t2{n}.
%
% function [m1 m2] = GreedyMatchTimesWrapper(t1, t2, d)
function [m1 m2] = GreedyMatchTimesWrapper(t1, t2, d)

if ~iscell(t1)
    [m1 m2] = greedymatchtimes(t1, t2, -d, d);
    return
end

m1 = cell(size(t1));
m2 = cell(size(t1));
for i = 1:length(t1)
    if i > length(t1) || i  > length(t2) || isempty(t1{i}) || isempty(t2{i})
        continue;
    end

    thisd = d(1);
    if length(d) > 1
        thisd = d(i);
    end

    [m1{i} m2{i}] = greedymatchtimes(t1{i}, t2{i}, -thisd, thisd);
end
