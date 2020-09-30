function spike_time_array = GetSpikeTimesFromAssignments(times, assignments, sampledelay)
% Given a set of times and assignments, create a cell array with times
% corresponding to each class (in samples). The (optional) third argument
% denotes the amount of delay to add to each sample, which is useful when
% compensating for group delay added in the filtering stage
if nargin < 3
    sampledelay = 0;
end

% Create a cell array of true spike times
classes = 1:max(assignments);
numclasses = length(classes);
spike_time_array = cell(numclasses, 1);
for i = 1:numclasses
    spike_time_array{i} = reshape(times(assignments == classes(i)), [], 1);
end

% Add sample delay from filtering to the spike times
for n=1:length(spike_time_array)
    spike_time_array{n} = spike_time_array{n} + sampledelay;
end
