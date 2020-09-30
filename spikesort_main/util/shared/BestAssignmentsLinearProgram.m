function [out, x] = BestAssignmentsLinearProgram(in)
% function [out, x] = BestAssignmentsLinearProgram(in)
%
% This program takes, as input, a matrix representing the "cost" of
% assigning row r to column c (where r is viewed as the estimated spike #
% and c is the true spike #), and returns a vector of row assignments
% for each column (so the n'th entry in the return vector is the estimated
% spike id # number assigned to ground truth spike id #r. It optionally
% also returns `x`, which is the raw permutation matrix.
%
% This can be used with any assignment matrix, e.g. one that quantifies the
% error in assigning a CBP waveform to a cluster, but the prototypical use
% for this is to assign CBP waveform spike times to ground truth spike
% times, so the comments below refer to that use case.
%
% For any such assignment, there is a set of errors - false negatives and
% positive - and the (r, c)'th entry of the matrix `in` is the sum of these
% errors.
%
% Our aim, then, is to get the permutation that minimizes the sum of all
% the errors, which is the best assignment. This can be written in a few
% different ways:
%
% 1. We want the permutation matrix P that minimizes sum(sum(P .* in)),
%    where .* is the dot product
% 2. We want the permutation matrix P that minimizes trace(P * in) =
%    trace(in * P). (This will be the inverse of the permutation matrix for
%    #1)
%
% The set of permutation matrices is not convex. The convex hull is the set
% of doubly stochastic matrices, or the Birkhoff polytope. It is well known
% that minimizing the sum of errors on this polytope is a linear program,
% since the sum of errors is a linear function. Furthermore, since the
% vertices of the Birkhoff polytope are permutation matrices, and the
% solution to any linear program is always at some vertex, we know that
% the solution will always be a permutation matrix.
%
%
%%@ Mike note for later:
% It is not, in general, guaranteed that there is only one unique
% assignment, and in that situation there will be an entire edge/face/etc
% of the polytope that minimizes the sum of errors. We want to be sure that
% MATLAB's `linprog` routine always chooses a vertex in this situation,
% rather than choosing an arbitrary vector on the solution set. To prevent
% the latter, we get it to choose a vertex by adding a random linear
% functional with very, very small coefficients to the result, so that the
% original solution set is still "approximately" minimal, but now one
% vertex in particular will randomly do slightly better with the slightly
% adjusted linear functional.

    % Assert that this is a square matrix. We do unbalanced assignment by
    % changing to balanced before calling this routine
    assert(size(in, 1) == size(in, 2), "Balanced assignments only!");
    N = size(in, 1);

    % first flatten to a vector
    flat = in(:);

    % Now get the equalities. We want the sum of each row and column to be
    % 1. These are just linear functionals on our flattened matrix. So, we
    % make a bunch of matrices which have all 1's in just one row (or
    % column), and then flatten them in the same way as the original. Each
    % flattened covector is just a row in our new matrix of equalities
    % (called "Aeq" by MATLAB)
    %
    % do rows first, and since these matrices are mostly sparse, may as
    % well make them officially sparse
    Aeq = sparse(2*N, N^2);
    for n=1:N
        tmp = sparse(N, N);
        tmp(n, :) = 1;  % set n'th row to 1, then flatten
        Aeq(n, :) = tmp(:);
    end

    % do cols next
    for n=1:N
        tmp = sparse(N, N);
        tmp(:, n) = 1;  % set n'th col to 1, then flatten
        Aeq(N + n, :) = tmp(:);
    end
    beq = ones(2*N, 1);

    % Now get the inequality matrices. We want all entries to be positive,
    % which means we want the negation of all entries to be less than 0
    % (which is how MATLAB wants us to express this). This is below
    A = -speye(N^2);
    b = sparse(N^2, 1);
    
    % Lastly, add a *very small* random linear functional to the objective
    % function, to ensure we always get a unique vertex.
    % We will seed the random number generator to the same thing each time,
    % just to make sure we always get the same results when debugging.
    rng(12345);
    randf = rand(length(flat), 1);
    randf = randf / (1000 * sum(randf));
    rng("shuffle");

    % That's it, run the linear program and reshape back to a square
    % matrix!
    x = linprog(randf + flat, A, b, Aeq, beq);
    x = reshape(x, N, N);
    
    for n=1:size(x, 2)
        out(n) = find(x(:, n));
    end
end