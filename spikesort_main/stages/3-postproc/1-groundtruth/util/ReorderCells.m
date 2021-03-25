function [bestorder, miss_mtx, fp_mtx, tp_mtx, ...
          all_err_mtx, total_score_mtx] = ...
    ReorderCells(true_cells, est_cells, spiketimeslack, balanced)
% Reorder cells defined by cell arrays of spike times to match based on
% spike timings.
%

%%@ The newer version of this function instead compares all possible
%%@ *pairings* of sorted cell labels to ground truth labels, then looks
%%@ for the matrix that minimizes the sum of errors using a linear program.
[bestorder, miss_mtx, fp_mtx, tp_mtx, all_err_mtx, total_score_mtx] = ...
    CalculateBestOrderingFast(true_cells, est_cells, spiketimeslack, balanced);

% Now, recover spike time and class vectors
%%@ The following code re-computes
%%@   CBPdata.ground_truth.true_spike_times and
%%@   CBPdata.ground_truth.true_spike_class. It doesn't even change
%%@ any permutations (until the end).
%%@
%%@ If needed, we could make this faster by passing these in as arguments (or
%%@ giving this routine access to the global CBPdata object), although this is
%%@ slightly more portable
times = cell2mat(true_cells);
[times timeidx] = sort(times);
classes = cell(size(true_cells));
for n = 1:length(classes)
    classes{n} = n * ones(size(true_cells{n}));
end
classes = cell2mat(classes);
classes = classes(timeidx);

% Lastly, permute the assignments
%%@ Note - this originally first computed the *inverse* permutation of
%%@ `bestorder`, then sent that to PermuteAssignments, which was hard-wired to
%%@ re-compute the assignments based on the inverse of whatever permutation
%%@ you give it - so, effectively, an inverse of an inverse. I have changed
%%@ PermuteAssignments so that it (by default) uses the permutation directly
%%@ rather than the inverse, unless the third argument "inverse" is specified.
%%@ FIXME - returning blank?
%%@@ later note - we no longer use assignment permutations, but rather
%%@@ assignment matrices, so there is no point returning an altered vector of
%%@@ true spike classes - one true spike class could correspond to *multiple*
%%@@ estimated. Just left for reference
% permuted_classes = PermuteAssignments(classes, bestorder);
% reordered_true_cells = GetSpikeTimeCellArrayFromVectors(times, permuted_classes);
