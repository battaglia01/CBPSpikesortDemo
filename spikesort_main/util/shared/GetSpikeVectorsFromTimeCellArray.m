% Given a cell array of spike times, return two arrays - one of times, and one
% of corresponding spike ID #'s for each time. The samples in the n'th entry in
% the original cell array will be assigned spike ID #n.
%
% function [times, assignments] = GetSpikeVectorsFromTimeCellArray(spike_time_array)
function [times, assignments] = GetSpikeVectorsFromTimeCellArray(spike_time_array)

tmp_segments = [];
tmp_assignments = [];
for n=1:length(spike_time_array)
    tmp_segments = [tmp_segments;round(spike_time_array{n})];
    tmp_assignments = ...
        [tmp_assignments;repmat(n, size(spike_time_array{n}))];
end
tmp_table = [tmp_segments tmp_assignments];
tmp_table = sortrows(tmp_table, 1);
times = tmp_table(:,1);
assignments = tmp_table(:,2);
