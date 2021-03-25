function ChangeGroundTruthAssignments(newperm, num_est, num_true, type)
    global CBPdata params;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First, check that this assignment is valid
    assert(type == "cbp" || type == "clustering", ...
           "Error: `type` parameter must be either 'cbp' or 'clustering'!");
    if params.general.raw_errors
        newperm = ValidateAssignments(newperm);
    else
        try
            ValidateAssignments(newperm);
        catch err
            errordlg(err.message, 'assignment Error!', 'modal');
            return;
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % If we got this far, the assignment is valid!
% 
%     % first get the old perm
%     oldperm = CBPdata.ground_truth.best_ordering;
% 
%     % then, we get the "un-reordered" original spike array
%     % note that, due to the way the indexing is done, "oldperm" is already
%     % the correct inverse assignment to undo the reordering
%     orig_spike_time_array_processed = ...
%         CBPdata.ground_truth.spike_time_array_processed(oldperm);
% 
%     % this strange code then computes the inverse of the new perm, which
%     % we need to do the new ordering
%     newperminv = sort(newperm);
%     newperminv(newperm) = newperminv;
% 
%     % then, we re-permute our recreated original, according to the new
%     % assignment
%     new_spike_time_array_processed = ...
%         orig_spike_time_array_processed(newperminv);
% 
%     % then we assign that, print the new evaluation results, and replot

    % Now we generate the matrix from that
    % increase the number of true
    num_rows = max(num_est, num_true);
    assignment_mtx = zeros(num_rows, num_true);
    for n=1:length(newperm)
        newvec = zeros(num_rows, 1);
        newvec(newperm{n}) = 1;
        assignment_mtx(:, n) = newvec;
    end
    
    if type == "clustering"
        CBPdata.ground_truth.best_ordering_cl = assignment_mtx;
    elseif type == "cbp"
        CBPdata.ground_truth.best_ordering_cbp = assignment_mtx;
    else
        error("Error - type in ChangeGroundTruthAssignments must be either " +...
              "'cbp' or 'clustering'!");
    end
    
%     CBPdata.ground_truth.spike_time_array_processed = ...
%         new_spike_time_array_processed;
    PrintSortingEvaluationResults;
	GroundTruthPlot;
end

function outperm = ValidateAssignments(newperm)
    global CBPdata params;
    % basic quantities
    num_est = CBPdata.waveform_refinement.num_waveforms;                         % number of estimated waveforms, without extra rows
    num_true = length(unique(CBPdata.ground_truth.true_spike_class));   % number of true waveforms, without extra columns
    
    if num_est == num_true
    % case 1: number of clusters = number of ground truth waveforms
        % first check each col has only one row assigned to it
        assert(all(cellfun(@length, newperm) == 1), ...
               "Invalid assignment - since the number of estimated and true " + ...
               "waveforms is equal, please make sure each column only has one " + ...
               "row assigned to it!");
        % also make sure our assignment is a permutation
        assert(isequal(sort(cell2mat(newperm)), 1:num_true), ...
               "Invalid assignment - please make sure each ID number " + ...
               "appears exactly once!");
    elseif num_est < num_true
    % case 2: number of estimated waveforms is less than ground truth
        % first check each col has only one row assigned to it
        assert(all(cellfun(@length, newperm) == 1), ...
               "Invalid assignment - since the number of estimated is *less* " + ...
               "than the number of true waveforms, please make sure each " + ...
               "column only has one row assigned to it!");
        % make sure there is one number per ground truth ID
        assert(length(newperm) == num_true, ...
               "Invalid assignment - please make sure there is exactly " + ...
               "one entry per ground truth ID#!");
        % make sure numbers are within range
        origperm = cell2mat(newperm);
        tmpperm = origperm(origperm > 0);
        assert(min(tmpperm) >= 1 && max(tmpperm) <= num_est, ...
               "Invalid assignment - please make sure the estimated " + ...
               "ID numbers are between 1 and " + num_est + "!");
        % make sure each row appears at most once
        assert(length(unique(tmpperm)) == length(tmpperm), ...
               "Invalid assignment - please make sure each estimated " + ...
               "ID number appears exactly once!")
        % make sure each row appears at least once
        assert(isequal(sort(unique(tmpperm)), 1:num_est), ...
               "Invalid assignment - please make sure each estimated " + ...
               "ID number appears exactly once!");
           
        % now give dummy IDs to the unassigned ones
        newperm(origperm == 0) = {setdiff(1:num_true, tmpperm)};
    elseif num_est > num_true
    % case 3: number of estimated waveforms is greater than ground truth
        % For this, we need to check if it's balanced or unbalanced
        if params.ground_truth_balanced
            % if balanced, then we again first check that the number of
            % cols is right
            assert(all(cellfun(@length, newperm) == 1), ...
               "Invalid assignment - since the number of estimated is *less* " + ...
               "than the number of true waveforms, please make sure each " + ...
               "column only has one row assigned to it!");
            % We also need to check the number of columns is correct
            assert(length(newperm) == num_true, ...
                   "Invalid assignment - please make sure there is exactly " + ...
                   "one entry per ground truth ID#!");
            % Then we need to check each number is in range
            tmpperm = cell2mat(newperm);
            assert(min(tmpperm) >= 1 && max(tmpperm) <= num_est, ...
               "Invalid assignment - please make sure the estimated " + ...
               "ID numbers are between 1 and " + num_est + "!");
            assert(length(tmpperm) == length(unique(tmpperm)), ...
                   "Invalid assignment - please make sure each estimated " + ...
                   "ID number appears at most once!");

            % now give dummy IDs to the unassigned ones
            newperm(end+1:num_est) = {setdiff(1:num_est, tmpperm)};
        else
            % unbalanced. instead we need to check the number of columns is
            % right, and that every row appears only once
            assert(length(newperm) == num_true, ...
                   "Invalid assignment - please make sure there is exactly " + ...
                   "one entry per ground truth ID#!");
            
            % make sure numbers are within range
            tmpperm = cellfun(@(x) x(:), newperm, 'UniformOutput', false);
            tmpperm = vertcat(tempperm{:});
            assert(min(tmpperm) >= 1 && max(tmpperm) <= num_est, ...
                   "Invalid assignment - please make sure the estimated " + ...
                   "ID numbers are between 1 and " + num_est + "!");
            % make sure each row appears at most once
            assert(length(unique(tmpperm)) == length(tmpperm), ...
                   "Invalid assignment - please make sure each estimated " + ...
                   "ID number appears exactly once!")
            % make sure each row appears at least once
            assert(isequal(sort(unique(tmpperm)), 1:num_est), ...
                   "Invalid assignment - please make sure each estimated " + ...
                   "ID number appears exactly once!");
        end
    end
    
    outperm = newperm;
end
