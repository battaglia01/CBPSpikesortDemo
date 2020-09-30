function ChangePermutation(newperm)
    global CBPdata params;

    % basic quantities
    num_est = CBPdata.waveformrefinement.num_waveforms;                         % number of estimated waveforms, without extra rows
    num_true = length(unique(CBPdata.groundtruth.true_spike_class));   % number of true waveforms, without extra columns

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First, check that this permutation is valid
    try
        if num_est == num_true
        % case 1: number of clusters = number of ground truth waveforms
            % make sure each permutation is equal exactly to 1:num_true
            assert(isequal(sort(newperm), 1:num_true), ...
                   "Invalid permutation - please make sure each ID number " + ...
                   "appears exactly once!");
        elseif num_est < num_true
        % case 2: number of estimated waveforms is less than ground truth
            % make sure there is one number per ground truth ID
            assert(length(newperm) == num_true, ...
                   "Invalid permutation - please make sure there is exactly " + ...
                   "one entry per ground truth ID#!");
            tmpperm = newperm(newperm > 0);
            % make sure numbers are within range
            assert(min(tmpperm) >= 1 && max(tmpperm) <= num_est, ...
                   "Invalid permutation - please make sure the estimated " + ...
                   "ID numbers are between 1 and " + num_est + "!");
            % make sure each row appears at most once
            assert(length(unique(tmpperm)) == length(tmpperm), ...
                   "Invalid permutation - please make sure each estimated " + ...
                   "ID number appears exactly once!")
            % make sure each row appears at least once
            assert(isequal(sort(unique(tmpperm)), 1:num_est), ...
                   "Invalid permutation - please make sure each estimated " + ...
                   "ID number appears exactly once!");

            % now give dummy IDs to the unassigned ones
            newperm(newperm == 0) = setdiff(1:num_true, tmpperm);
        elseif num_est > num_true
            % case 3: number of estimated waveforms is greater than ground truth
            assert(length(newperm) == num_true, ...
                   "Invalid permutation - please make sure there is exactly " + ...
                   "one entry per ground truth ID#!");
            assert(min(newperm) >= 1 && max(newperm) <= num_est, ...
               "Invalid permutation - please make sure the estimated " + ...
               "ID numbers are between 1 and " + num_est + "!");
            assert(length(newperm) == length(unique(newperm)), ...
                   "Invalid permutation - please make sure each estimated " + ...
                   "ID number appears at most once!");

            % now give dummy IDs to the unassigned ones
            newperm(end+1:num_est) = setdiff(1:num_est, newperm);
        end
    catch err
        errordlg(err.message, 'Permutation Error!', 'modal');
        return;
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If we got this far, the permutation is valid!

    % first get the old perm
    oldperm = CBPdata.groundtruth.best_ordering;

    % then, we get the "un-reordered" original spike array
    % note that, due to the way the indexing is done, "oldperm" is already
    % the correct inverse permutation to undo the reordering
    orig_spike_time_array_processed = ...
        CBPdata.groundtruth.spike_time_array_processed(oldperm);

    % this strange code then computes the inverse of the new perm, which
    % we need to do the new ordering
    newperminv = sort(newperm);
    newperminv(newperm) = newperminv;

    % then, we re-permute our recreated original, according to the new
    % permutation
    new_spike_time_array_processed = ...
        orig_spike_time_array_processed(newperminv);

    % then we assign that, print the new evaluation results, and replot
    CBPdata.groundtruth.best_ordering = newperm;
    CBPdata.groundtruth.spike_time_array_processed = ...
        new_spike_time_array_processed;
    PrintSortingEvaluationResults;
	GroundTruthPlot;
end
