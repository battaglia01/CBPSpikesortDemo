% One thing that we need, and which we will use again and again,
% is a master array of "assignments" matching up CBP, clustering, and
% ground truth - even if the numbers of each of these differ or if ground
% truth doesn't exist.
%
% For instance, one array could be
%     { [true:1 cbp:1 cl:1    ],
%       [true:2 cbp:2 cl:[2 3]],
%       [true:3 cbp:0 cl:4    ],
%       [true:0 cbp:3 cl:5    ],
%       ...                      }
%
% So in this assignment array, we have:
%   true#1 = CBP#1 = Cl#1
%   true#2 = CBP#2 = Cl#[2,3]
%   true#3 = CBP#X = Cl#4
%   true#X = CBP#3 = Cl#5
%
% Instead of storing
% Where "X" means unassigned.
%
% To build this, we'll first go through all the ground truth (until we have
% none left), then go through all the CBP waveforms (until we have none
% left), then go through all the Clustering waveforms (to see what
% remains).
%
% function assignments = ...
%     CalculateAssignmentTriples(cl_waveforms, cbp_waveforms, true_waveforms, ...
%                                assignment_mtx_cl_true, assignment_mtx_cbp_true, ...
%                                assignment_mtx_cl_cbp)

function assignments = ...
    CalculateAssignmentTriples(cl_waveforms, cbp_waveforms, true_waveforms, ...
                               assignment_mtx_cl_true, assignment_mtx_cbp_true, ...
                               assignment_mtx_cl_cbp)

% First get some basic variables:
find_cl_true_assignment = @(x) find(assignment_mtx_cl_true(:, x));
find_cbp_true_assignment = @(x) find(assignment_mtx_cbp_true(:, x));
find_cl_cbp_assignment = @(x) find(assignment_mtx_cl_cbp(:, x));

num_true_waveforms = length(true_waveforms);
num_cbp_waveforms = length(cbp_waveforms);
num_cl_waveforms = length(cl_waveforms);
max_num_waveforms = ...
    max([num_true_waveforms, num_cbp_waveforms, num_cl_waveforms]);

% Now we iterate through all of these indices and build our array.
assignments = {};
cbp_used_so_far = [];
cl_used_so_far = [];
% First start with the ground truth waveforms.
for n=1:num_true_waveforms
    new_assignment = [];

    % Add the matching waveforms from the best_orderings.
    new_assignment.true = n;
    new_assignment.cbp = find_cbp_true_assignment(n);
    new_assignment.cl = find_cl_true_assignment(n);

    % now, before we're done, let's make sure that new_assignment.cbp and
    % new_assignment.cl don't have any "dummy" values (e.g. there were less
    % of them than true truth, and they were assigned just random dummy
    % values in a balanced assignment problem
    new_assignment.cbp(new_assignment.cbp > num_cbp_waveforms) = 0;
    new_assignment.cl(new_assignment.cl > num_cl_waveforms) = 0;

    % also, let's update the ones we've used so far
    cbp_used_so_far = ...
        union(cbp_used_so_far, new_assignment.cbp(new_assignment.cbp > 0));
    cl_used_so_far = ...
            union(cl_used_so_far, new_assignment.cl(new_assignment.cl > 0));

	% now add it
    assignments{end+1} = new_assignment;
end


% Now, there may be some CBP waveforms remaining that weren't assigned to
% any ground truth - which should happen if there's no ground truth, or if
% we have more ground truth than CBP waveforms and this was a "balanced"
% assignment. We then iterate on the remaining CBP waveforms, and use the
% best-fit assignment matrix from the *WaveformRefinement* stage to get its
% matching cluster.
cbp_remaining = setdiff(1:num_cbp_waveforms, cbp_used_so_far);
for ind=1:length(cbp_remaining)
    n = cbp_remaining(ind);

    new_assignment = [];

    % Set true to 0, set cbp to n, and get the ordering from the
    % WaveformRefinement cluster_assignment_mtx
    new_assignment.true = 0;
    new_assignment.cbp = n;
    new_assignment.cl = find_cl_cbp_assignment(n);

    % Now, before we're done, we need to do two things...
    % First, we need to eliminate any indices that were already used
    % previously, as we don't want any clustering waveform to appear.
    % twice. If we've eliminated all, we set it to 0.
    new_assignment.cl = ...
        new_assignment.cl(~ismember(new_assignment.cl, cl_used_so_far));
    if isempty(new_assignment.cl)
        new_assignment.cl = 0;
    end

    % Then, we also need to make sure that new_assignment.cl
    % doesn't have any "dummy" values, similar to before. cbp can't,
    % because we're only using valid waveforms that are remaining...
    new_assignment.cl(new_assignment.cl > num_cl_waveforms) = 0;

    % Lastly, let's update the ones we've used so far.
    cbp_used_so_far = ...
        union(cbp_used_so_far, new_assignment.cbp(new_assignment.cbp > 0));
    cl_used_so_far = ...
            union(cl_used_so_far, new_assignment.cl(new_assignment.cl > 0));

	% now add it
    assignments{end+1} = new_assignment;
end


% Now, we go through whatever clustering waveforms remain, and give them
% matching ground truth and CBP waveforms of "0" each.
cl_remaining = setdiff(1:num_cl_waveforms, cl_used_so_far);
for ind=1:length(cl_remaining)
    n = cl_remaining(ind);

    new_assignment = [];

    % Set true to 0, set cbp to 0, and get cl to n.
    new_assignment.true = 0;
    new_assignment.cbp = 0;
    new_assignment.cl = n;

    % We don't need to update any dummy values, since we know each of the
    % values in cl_remaining are "true" waveform values.

    % Now let's update the ones used so far
    cl_used_so_far = ...
            union(cl_used_so_far, new_assignment.cl(new_assignment.cl > 0));

	% now add it
    assignments{end+1} = new_assignment;
end

% Now, to sanity check, assert all of the CBP and clustering waveforms
% that have been "used" are 1:num_cbp_waveforms, and 1:num_cl_waveforms.
assert(isequal([1:num_cbp_waveforms]', sort(cbp_used_so_far(:))), ...
    "Internal Error: ~isequal(1:num_cbp_waveforms, sort(cbp_used_so_far))!");
assert(isequal([1:num_cl_waveforms]', sort(cl_used_so_far(:))), ...
    "Internal Error: ~isequal(1:num_cl_waveforms, sort(cl_used_so_far))!");
