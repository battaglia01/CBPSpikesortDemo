function [misses, false_positives, true_positives] = ComputeMetrics(est_times, true_times, slack)
% Given a set of true/est spike times, compute # errors

%%@ NOTE - it's good to sort the input just in case it's not in order.
%%@ If this is too slow, we can remove though...
%%@ OPT
[est_matches true_matches] = GreedyMatchTimesWrapper(sort(est_times), sort(true_times), slack);

% Do a greedy matching by marching through true spikes.
misses          = sum(true_matches == 0);
false_positives = sum(est_matches  == 0);
true_positives  = nnz(true_matches);
assert(nnz(true_matches) == nnz(est_matches));