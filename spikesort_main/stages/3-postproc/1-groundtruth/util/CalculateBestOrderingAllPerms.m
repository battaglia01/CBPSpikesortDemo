%%@ Mike's note: this is the old function that computes the optimal
%%@ permutation of assignments of ground truth waveforms to estimated
%%@ waveforms. It is *much* slower (growing factorially with the number of
%%@ waveforms) and has since been superceded by CalculateBestOrderingFast.m
%%@ which uses a linear programming based approach. This is left for
%%@ reference but no longer is called anywhere in the code.

function best_ordering = CalculateBestOrderingAllPerms(true_cells, est_cells, slack)
% Wrapper around EvaluateSorting that tries all permutations of waveforms to
% find best match between computed waveforms and true units.

num_est_wfs = length(est_cells);
num_true_wfs = length(true_cells);

% Enumerate all possible matchings of est. waveforms to true waveforms
orderings = perms(1 : num_est_wfs);
if (num_true_wfs < num_est_wfs)
    sk = factorial(num_est_wfs - num_true_wfs);
    orderings = orderings(1 : sk : end, 1 : num_true_wfs);
end

% Evaluate misses/false positives for each ordering
tm = zeros(size(orderings, 1), 1);
tfp = zeros(size(tm));
parfor i = 1 : size(orderings, 1) % for each permutation
    [m, fp] = EvaluateSortingLowLevel(est_cells(orderings(i, :)), true_cells, slack);
	% total misses/false positives across waveforms
    tm(i) = sum(m);
    tfp(i) = sum(fp);
end

% Pick the best ordering.
[blah, min_idx] = min(tm + tfp);
best_ordering = orderings(min_idx, :);
