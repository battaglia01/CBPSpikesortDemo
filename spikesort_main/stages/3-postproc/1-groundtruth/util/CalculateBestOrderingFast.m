function [best_ordering, miss_mtx, fp_mtx, all_err_mtx] = ...
    CalculateBestOrderingFast(true_cells, est_cells, slack)
% Wrapper around EvaluateSorting that:
% 1. tries all possible pairings of waveform #'s and true spike #'s
% 2. stores the result in a matrix, and
% 3. gets the best possible assignment
%
% This function returns a vector in which the n'th entry is the estimated
% waveform ID # corresponding to ground truth waveform ID #n.

num_est_wfs = length(est_cells);
num_true_wfs = length(true_cells);
N = max(num_true_wfs, num_est_wfs);

% Now get all possible pairings. Make this a square matrix for now; we will
% fill in the extra rows/columns below to make this a balanced assignment
% problem
miss_mtx = zeros(N, N);
fp_mtx = zeros(N, N);
all_err_mtx = zeros(N, N);
for a=1:num_est_wfs
    for b=1:num_true_wfs
        % call ComputeErrors directly and skip EvaluateSortingLowLevel,
        % since we're just doing one pair at a time.
        % The combined error score is the misses plus the false positives,
        % same as in the original CalculateBestOrdering
        [m, fp] = ComputeErrors(est_cells{a}, true_cells{b}, slack);
        miss_mtx(a, b) = m;
        fp_mtx(a, b) = fp;
    end
end

% Now, if we have *less* rows than columns, that means we have less
% sorted spike types than ground truth types. In this situation, we
% will have some sorted spike waveform types left that we don't match
% to any ground truth waveforms. For these waveforms, we take the
% "unmatched" ground truth waveforms and treat them as having a 100%
% false negative rate (and 0% false positive rate).
%
% We formalize this by turning the original unbalanced problem as a
% balanced assignment problem. We treat the new rows in the matrix,
% created in the step above, as new assignment types for the ground
% truth waveform, corresponding to "no sorted spike ID." For each
% column in the matrix, the new rows are all set to the maximum number
% of false negatives possible for that column (e.g. the total number of
% spikes in that ground truth column) and no false positives.
if num_est_wfs < num_true_wfs
    for n=1:num_true_wfs
        miss_mtx(num_est_wfs+1:end, n) = length(true_cells{n});
    end
end

% However, if we have *more* rows than columns, that means we have more
% sorted spike types than ground truth types. This situation could arise
% for a few reasons. One reason, probably the most common, is that we only
% have partial ground truth, meaning we should assume that there simply
% isn't any ground truth for this channel at all. In this situation, we
% expand the number of columns, basically creating a bunch of "no ground
% truth ID" categories that we can assign sorted spike ID's to. These
% should all have 0 false negatives or false positives, meaning we don't
% penalize any sorted spike ID just for being matched as unassigned -
% instead, we simply look for the subset of spike ID's that *does* best
% match the existing ground truth set.
%
% Since we already zero-padded above, we need not do anything here.
%
%%@ Mike's note for later:
% Another possible situation is if we have multiple spike ID's that
% correspond to the same ground truth ID. This could happen if, for
% instance, there is sufficient variance within a single ground truth ID
% for our sorter to treat it as two different spike waveform types. If this
% happens, we would want to let multiple sorted spike ID #'s be assigned to
% the same ground truth ID #. This would involve modifying the linear
% program slightly, so for now we will just treat it as the prior
% situation (which is how the previous function did it), although in the
% future we can add a param to modify this.

all_err_mtx = miss_mtx + fp_mtx;
best_ordering = BestAssignmentsLinearProgram(all_err_mtx);