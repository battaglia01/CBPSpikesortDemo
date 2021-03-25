function newassign = PermuteAssignments(assign, perm, inverse)
% function newassign = PermuteAssignments(assign, perm, inverse)
%
% A simple function that takes a set of assignments (`assign`), represented
% as integers from 1 to N, and swaps/permutes them according to some
% arbitrary permutation (`perm`).
%
% If the third parameter is not set to the word "inverse," this replaces all
% appearances of the number `n` with `perm(n)`.
%
% If it is set to "inverse", the permutation swaps all appearances of `n`, in
% `assign`, with the index in which `n` appears in the array `perm`.
% So if `perm` is [2 3 1], then all instances of 1 in `assign` are changed
% to 3, because 1 is is in the third position in `perm`. Likewise, 2
% becomes 1, and 3 becomes 2.
%
% Example: PermuteAssignments([1 2 3 2 1], [2 3 1]) = [3 1 2 1 3]

if nargin == 3 && inverse == "inverse"
    perm = invperm(perm);
end

newassign = zeros(size(assign));
for i = 1:length(perm)
    newassign(assign == i) = perm(i);
end
