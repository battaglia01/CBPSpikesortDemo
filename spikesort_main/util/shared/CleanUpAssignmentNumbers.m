% This simple helper function takes a vector of assignments, and makes sure the
% numbers are contiguous from 1-N. Useful when merging or removing clusters, or
% when parsing a file that may have non-contiguous clusters.
%
% function out = CleanUpAssignmentNumbers(assignments)
function out = CleanUpAssignmentNumbers(assignments)
    % makes sure we start at zero
    assignments = assignments - min(assignments) + 1;
    next_num = 1;
    for n=1:max(assignments)
        assignment_inds = find(assignments == n);
        if ~isempty(assignment_inds)
            assignments(assignment_inds) = next_num;
            next_num = next_num + 1;
        end
    end
    out = assignments;
end
