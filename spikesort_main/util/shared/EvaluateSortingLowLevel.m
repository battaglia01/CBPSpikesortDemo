function [total_misses, total_false_positives, misses, false_positives] = ...
    EvaluateSortingLowLevel(est_times, true_times, slack)
% Low level version where only spike times are used (amplitudes already
% assumed above threshold)
%
% est_times: cell array of estimated spike times for each waveform
%
% true_times : cell array of true spike times for each waveform
%              NOTE: this assumes that the waveform numbers for est_times
%              and true_times match, such that est_times{1:m} is matched
%              with true_times{1:m} where
%              m = min(length(est_times), length(true_times)). 
%
% slack : maximum number of samples between est/true spike
%         to be considered a match
%
% Returns:
%   total_misses/false_positives : total numbers of misses/false positives
%                                  PER WAVEFORM
%   misses : cell array of same size as true_times indicating misses
%   false_postives : cell array of same size as est_times


% set up some local reused variables
num_waveforms = length(est_times);
min_num_waveforms = min(num_waveforms, length(true_times));
misses = cell(length(true_times), 1);
false_positives = cell(length(est_times), 1);
total_misses = zeros(length(true_times), 1);

total_false_positives = zeros(length(est_times), 1);
for i=1:min_num_waveforms

    % If true_times{i} is empty, assume we didn't have truth for this cell
    % and skip
    if isempty(true_times{i})
        continue;
    end

    [misses{i}, false_positives{i}] = ...
        ComputeErrors(est_times{i}, true_times{i}, slack);
    total_misses(i) = sum(misses{i});
    total_false_positives(i) = sum(false_positives{i});
end

% All remaining true spikes are missed
for i = (min_num_waveforms + 1) : length(true_times)
    total_misses(i) = sum(misses{i});
    misses{i} = true(size(true_times{i}));
end

% All remaning est spikes are false positives
for i = (min_num_waveforms + 1) : length(est_times)
    % Assume empty true_times means we didn't really have truth for this
    % unit, so skip it
    %%@ Mike's note - the following line seems to negate the entire loop!
    %%@ min_num_waveforms = min(length(est_times), length(true_times)).
    %%@ Thus, if est_times is shorter, this loop never begins at all,
    %%@ and if true_times is shorter, then the next line skips everything!
    if i > length(true_times) || isempty(true_times{i}), continue; end

    error("DEBUGGING MIKE NOTE - Should be inaccessible!");
    false_positives{i} = true(size(est_times{i}));
    total_false_positives(i) = sum(false_positives{i});
end
