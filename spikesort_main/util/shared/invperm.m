function out = invperm(in)
% Quick function that simply returns the inverse of a permutation.
% `in` should be a vector.
    out = [];
    out(in) = 1:length(in);
end