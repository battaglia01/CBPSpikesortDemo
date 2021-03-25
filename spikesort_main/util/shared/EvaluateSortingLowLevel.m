function [total_misses, total_false_positives, total_true_positives, ...
          misses, false_positives, true_positives] = ...
    EvaluateSortingLowLevel(est_times, true_times, assignment_mtx, slack)
% Low level version where only spike times are used (amplitudes already
% assumed above threshold)
%
% est_times: cell array of estimated spike times for each waveform
%
% true_times : cell array of true spike times for each waveform
%              NOTE: this assumes that the waveform numbers for modified_est_times
%              and true_times match, such that modified_est_times{1:m} is matched
%              with true_times{1:m} where
%              m = min(length(modified_est_times), length(true_times)).
%
% slack : maximum number of samples between est/true spike
%         to be considered a match
%
% Returns:
%   total_misses/false_positives : total numbers of misses/false positives
%                                  PER WAVEFORM
%   misses : cell array of same size as true_times indicating misses
%   false_positives : cell array of same size as modified_est_times

% Now, we may be in a situation where we have more estimated than ground
% truth. If that's true, then the first thing we will do is *merge* the
% estimated which share the same ground truth assignment, so that we don't
% get separate false negatives for each estimated, but a combined false
% negative for the various merged.
modified_est_times = {};
for n=1:size(assignment_mtx, 2)
    cur_col = assignment_mtx(:, n);
    % The various entries that are "1" in this column correspond to the
    % different estimated waveforms that are assigned to this ground truth
    % waveform
    indices_to_merge = find(cur_col);
    
    indices_to_merge = indices_to_merge(indices_to_merge <= length(est_times));
    merged_spike_times_arr = est_times(indices_to_merge);
    % We now need to flatten the vectors in the cell array
    merged_spike_times_arr = ...
        cellfun(@(x) x(:), merged_spike_times_arr, 'UniformOutput', false);
    % And also we need to concatenate into a single vector and sort
    merged_spike_times = sort(vertcat(merged_spike_times_arr{:}));
    modified_est_times{n} = merged_spike_times;
end

% set up some local reused variables
num_waveforms = length(modified_est_times);
min_num_waveforms = min(num_waveforms, length(true_times));

misses = cell(length(true_times), 1);
false_positives = cell(length(modified_est_times), 1);
true_positives = cell(min_num_waveforms, 1);

total_misses = zeros(length(true_times), 1);
total_false_positives = zeros(length(modified_est_times), 1);
total_true_positives = zeros(min_num_waveforms, 1);
for i=1:min_num_waveforms

    % If true_times{i} is empty, assume we didn't have truth for this cell
    % and skip
    if isempty(true_times{i})
        continue;
    end

    %%@ add true positives here as well
    [misses{i}, false_positives{i}, true_positives{i}] = ...
        ComputeMetrics(modified_est_times{i}, true_times{i}, slack);
    total_misses(i) = sum(misses{i});
    total_false_positives(i) = sum(false_positives{i});
    total_true_positives(i) = sum(true_positives{i});
end

% All remaining true spikes are missed
for i = (min_num_waveforms + 1) : length(true_times)
    total_misses(i) = sum(misses{i});
    misses{i} = true(size(true_times{i}));
end

% All remaning est spikes are false positives
for i = (min_num_waveforms + 1) : length(modified_est_times)
    % Assume empty true_times means we didn't really have truth for this
    % unit, so skip it
    %%@ Mike's note - the following line seems to negate the entire loop!
    %%@ min_num_waveforms = min(length(modified_est_times), length(true_times)).
    %%@ Thus, if modified_est_times is shorter, this loop never begins at all,
    %%@ and if true_times is shorter, then the next line skips everything!
    if i > length(true_times) || isempty(true_times{i}), continue; end

    error("DEBUGGING MIKE NOTE - Should be inaccessible!");
    false_positives{i} = true(size(modified_est_times{i}));
    total_false_positives(i) = sum(false_positives{i});
end
