function str = SortingEvaluationStr(true_times, est_times, total_true_positives, total_misses, total_false_positives)

% Get total number of true spikes                
total_true = 0;
for i = 1:length(true_times)
    total_true = total_true + length(true_times{i});
end

% Get total number of est. spikes
total_est = 0;
for i = 1 : length(est_times)
    total_est = total_est + length(est_times{i});
end

str = sprintf('TruePositives: %d/%d (%.1f%%)\tMisses: %d/%d (%.1f%%)\tFalsePositives: %d/%d (%.1f%%)\n', ...
        sum(total_true_positives), total_true, ...
        sum(total_true_positives) / total_true * 100, ...
        sum(total_misses), total_true, ...
        sum(total_misses) / total_true * 100, ...
        sum(total_false_positives), total_est, ...
        sum(total_false_positives) / total_est * 100);
