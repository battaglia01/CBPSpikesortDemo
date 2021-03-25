function [best_ordering, miss_mtx, fp_mtx, tp_mtx, all_err_mtx, total_score_mtx] = ...
    CalculateBestOrderingFast(true_cells, est_cells, slack, balanced)
% Wrapper around ComputeMetrics that:
% 1. tries all possible pairings of waveform #'s and true spike #'s
% 2. stores the result in a matrix, and
% 3. gets the best possible assignment
%
% This function returns a vector in which the n'th entry is the estimated
% waveform ID # corresponding to ground truth waveform ID #n.

num_est_wfs = length(est_cells);
num_true_wfs = length(true_cells);

% Now get all possible pairings.
miss_mtx = zeros(num_est_wfs, num_true_wfs);
fp_mtx = zeros(num_est_wfs, num_true_wfs);
tp_mtx = zeros(num_est_wfs, num_true_wfs);
all_err_mtx = zeros(num_est_wfs, num_true_wfs);
total_score_mtx = zeros(num_est_wfs, num_true_wfs);

for a=1:num_est_wfs
    for b=1:num_true_wfs
        % call ComputeMetrics directly and skip EvaluateSortingLowLevel,
        % since we're just doing one pair at a time.
        % The combined error score is the misses plus the false positives,
        % same as in the original CalculateBestOrdering
        [m, fp, tp] = ComputeMetrics(est_cells{a}, true_cells{b}, slack);
        miss_mtx(a, b) = m;
        fp_mtx(a, b) = fp;
        tp_mtx(a, b) = tp;
    end
end

% Now, suppose we have that `balanced` = true. Then we
% want to convert our "unbalanced" problem into a "balanced" one. To do
% this, we simply zero-pad the matrix to make it square.
if balanced
    max_dim = max(num_true_wfs, num_est_wfs);
    miss_mtx(max_dim, max_dim) = 0;
    fp_mtx(max_dim, max_dim) = 0;
    tp_mtx(max_dim, max_dim) = 0;
    all_err_mtx(max_dim, max_dim) = 0;
    total_score_mtx(max_dim, max_dim) = 0;
end

% If we have exactly as many estimated waveforms as true waveforms,
% then we have a "balanced assignment" problem, and a square matrix.
% In this situation, we want the rows and columns to have "exactly one" 1
% in each, and we want to maximize the number of
% true positives - false negatives - false positives.
% This also applies if our "balanced" parameter is true.
if num_est_wfs == num_true_wfs || balanced
    matrix_to_optimize = tp_mtx - fp_mtx - miss_mtx;
    RowCriterion = 'exactly-one';
    ColCriterion = 'exactly-one';
end

% Now, if we have *less* rows than columns, that means we have less
% sorted spike types than ground truth types. In this situation, we
% will have some sorted spike waveform types left that we don't match
% to any ground truth waveforms. For these waveforms, we take the
% "unmatched" ground truth waveforms and treat them as having a 100%
% false negative rate (and 0% false positive rate).
%
% We formalize this by turning the original unbalanced problem into a
% balanced assignment problem. We treat the new rows in the matrix,
% created in the step above, as new assignment types for the ground
% truth waveform, corresponding to "no sorted spike ID." For each
% column in the matrix, the new rows are all set to the maximum number
% of false negatives possible for that column (e.g. the total number of
% spikes in that ground truth column) and no false positives.
%
% Note we only want to do this if our "balanced" parameter is false.
if num_est_wfs < num_true_wfs && ~balanced
    % We will also extend the various error matrices so that they become square.
    % We do this by setting the (N,N)'th coordinate to 0, where N is the numberf
    % of columns, and MATLAB will auto-extend and zero-pad.
    miss_mtx(num_true_wfs, num_true_wfs) = 0;
    fp_mtx(num_true_wfs, num_true_wfs) = 0;
    tp_mtx(num_true_wfs, num_true_wfs) = 0;
    all_err_mtx(num_true_wfs, num_true_wfs) = 0;
    total_score_mtx(num_true_wfs, num_true_wfs) = 0;

    for n=1:num_true_wfs
        miss_mtx(num_est_wfs+1:end, n) = length(true_cells{n});
    end

    % For this, we look for the matrix that maximizes the score
    % "true positives - false positives - misses."
    % This was originally just minimizing "false positives + misses" and
    % ignoring true positives.
    %%@ May be good to put into a param
    matrix_to_optimize = tp_mtx - fp_mtx - miss_mtx;
    RowCriterion = 'exactly-one';
    ColCriterion = 'exactly-one';
end

% However, if we have *more* rows than columns, that means we have more
% sorted spike types than ground truth types. This situation could arise
% for a few reasons, but most commonly, the spike sorter was even more sensitive
% than needed and thinks that one "true" cluster is really two.
%
% For this variant, the main possible situation is if we have multiple spike
% ID's that correspond to the same ground truth ID. This could happen if, for
% instance, there is sufficient variance within a single ground truth ID
% for our sorter to treat it as two different spike waveform types. If this
% happens, we let multiple sorted spike ID #'s be assigned to
% the same ground truth ID #. To do this, we set the "RowCriterion" to
% "exactly-one" and the "ColCriterion" to "at-least-one", which means that every
% ground truth has *some* estimated waveform assigned to it, and every estimated
% waveform is assigned to *something*.
%
% To do this, we need to *ignore false negatives* for the linear program! This
% is because, for instance, if some ground truth waveform has 1000 spikes, and
% there are two estimated spikes which both match it and have 500 each, both
% waveforms will have 500 "misses" - but jointly, they have 0 misses. In order
% to get a good estimate of what the best assignments may be, we will only look
% at "true positives" and "false positives" in this situation.
%
% We can also set this up so that we don't even require the ColCriterion to be
% "at-least-one", which means we permit some ground truths to be "unassigned,"
% if we want. May be useful to put into a parameter later.
%
% Again, need to make sure "balanced" is false.

if num_est_wfs > num_true_wfs && ~balanced
    matrix_to_optimize = tp_mtx - fp_mtx;
    RowCriterion = 'exactly-one';
    ColCriterion = 'at-least-one';
end

all_err_mtx = miss_mtx + fp_mtx;
best_ordering = ...
    BestGeneralizedAssignmentsLinearProgram(...
        matrix_to_optimize, ...
        "RowCriterion", RowCriterion, ...
        "ColCriterion", ColCriterion);
