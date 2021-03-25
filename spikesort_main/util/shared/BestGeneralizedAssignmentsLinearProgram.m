function out = BestGeneralizedAssignmentsLinearProgram(in, varargin)
% function out = BestGeneralizedAssignmentsLinearProgram(in, varargin)
%
% This program solves a generalized version of the assignment problem using a
% linear program.
%
% Instead of each row and column having exactly one "1" entry, you can specify
% which restrictions you want, for both rows and columns, independently, using
% the options "RowCriterion" and "ColCriterion", and the values "unconstrained",
% "at-least-one", "exactly-one", and "at-most-one".
%
% An example:
%
%     out = BestGeneralizedAssignmentsLinearProgram(in, ...
%               "RowCriterion", "exactly-one", ...
%               "ColCriterion", "exactly-one")
%
% is the usual balanced assignment problem. If we want to require exactly one
% "1" per row, but don't care how many are in a single column, we get
%
%     out = BestGeneralizedAssignmentsLinearProgram(in, ...
%               "RowCriterion", "exactly-one", ...
%               "ColCriterion", "unconstrained")
%
% If no criteria are specified, the default is "exactly-one."
%
% Certain combinations of criteria, such as "at-least-one" on rows and
% "at-most-one" on cols, are equivalent to "exactly-one" for both (i.e. the
% usual balanced assignment problem). In this situation, it is required that the
% input matrix be square, and this program checks for that.
%
% Certain combinations yield nonsensical results, such as both criteria being
% unconstrained, or both being just "at least one" - which are difficult to
% interpret as assignments, and tend to converge to just the matrix of pointwise
% signs of the input matrix.
%
% This program takes, as input, a matrix representing the "score" of
% assigning row r to column c (where r is viewed as the estimated spike #
% and c is the true spike #), and returns a vector of row assignments
% for each column (so the n'th entry in the return vector is the estimated
% spike id # number assigned to ground truth spike id #r. It optionally
% also returns `x`, which is the raw permutation matrix.
%
% This can be used with any assignment matrix, e.g. one that quantifies some
% score in assigning a CBP waveform to a cluster, but the prototypical use
% for this is to assign CBP waveform spike times to ground truth spike
% times, so the comments below refer to that use case.
%
% For any such assignment, there is a set of true positives, false negatives,
% and false positives. The (r, c)'th entry of the matrix `in` is the sum of the
% true positives, minus the sum of the errors.
%
% Our aim, then, is to get the permutation that maximizes the sum of all the
% scores, which is the best assignment. This can be written in a few different
% ways:
%
% 1. We want the permutation matrix P that maximizes sum(sum(P .* in)),
%    where .* is the dot product
% 2. We want the permutation matrix P that maximizes trace(P * in) =
%    trace(in * P). (This will be the inverse of the permutation matrix for
%    #1)
%
% The set of permutation matrices is not convex. The convex hull is the set
% of doubly stochastic matrices, or the Birkhoff polytope. It is well known
% that maximizing the sum of scores on this polytope is a linear program,
% since the sum of scores is a linear function. Furthermore, since the
% vertices of the Birkhoff polytope are permutation matrices, and the
% solution to any linear program is always at some vertex, we know that
% the solution will always be a permutation matrix.
%
%
%%@ Mike note for later:
% It is not, in general, guaranteed that there is only one unique
% assignment, and in that situation there will be an entire edge/face/etc
% of the polytope that maximizes the sum of scores. We want to be sure that
% MATLAB's `linprog` routine always chooses a vertex in this situation,
% rather than choosing an arbitrary vector on the solution set. To prevent
% the latter, we get it to choose a vertex by adding a random linear
% functional with very, very small coefficients to the result, so that the
% original solution set is still "approximately" maximal, but now one
% vertex in particular will randomly do slightly better with the slightly
% adjusted linear functional.

    p = inputParser;
    criteria = ["unconstrained", "at-least-one", "exactly-one", "at-most-one"];
    p.addParameter("RowCriterion", "exactly-one", @(x) ismember(x, criteria));
    p.addParameter("ColCriterion", "exactly-one", @(x) ismember(x, criteria));
    p.parse(varargin{:});

    % now make sure we're only using the right combinations
    rowcrit = p.Results.RowCriterion;
    colcrit = p.Results.ColCriterion;
    assert(~(rowcrit == "unconstrained" && colcrit == "unconstrained"), ...
           "Row and column can't both be unconstrained!");
    assert(~(rowcrit == "unconstrained" && colcrit == "at-least-one"), ...
           "Either the rows or columns need to be at-most-one or exactly-one!");
    assert(~(rowcrit == "at-least-one" && colcrit == "unconstrained"), ...
           "Either the rows or columns need to be at-most-one or exactly-one!");
    assert(~(rowcrit == "at-least-one" && colcrit == "at-least-one"), ...
           "Either the rows or columns need to be at-most-one or exactly-one!");

    % also make sure if the user has (perhaps inadvertently) specified a
    % combination equivalent to the usual balanced assignment problem, that the
    % input is square
    implies = @(a, b) ~a | b;
%%@ note - these don't really need to have a square matrix - leaving for
%%@ reference and debugging
%     assert(implies(rowcrit == "exactly-one" && colcrit == "at-least-one", ...
%                    size(in, 1) == size(in, 2)), ...
%            "Balanced assignment problem - must have a square input matrix!");
%     assert(implies(rowcrit == "at-most-one" && colcrit == "at-least-one", ...
%                    size(in, 1) == size(in, 2)), ...
%            "Balanced assignment problem - must have a square input matrix!");
%     assert(implies(rowcrit == "at-least-one" && colcrit == "exactly-one", ...
%                    size(in, 1) == size(in, 2)), ...
%            "Balanced assignment problem - must have a square input matrix!");
%     assert(implies(rowcrit == "at-least-one" && colcrit == "at-most-one", ...
%                    size(in, 1) == size(in, 2)), ...
%            "Balanced assignment problem - must have a square input matrix!");
    assert(implies(rowcrit == "exactly-one" && colcrit == "exactly-one", ...
                   size(in, 1) == size(in, 2)), ...
           "Balanced assignment problem - must have a square input matrix!");
    assert(implies(rowcrit == "at-most-one" && colcrit == "exactly-one", ...
                   size(in, 1) == size(in, 2)), ...
           "Balanced assignment problem - must have a square input matrix!");
    assert(implies(rowcrit == "exactly-one" && colcrit == "at-most-one", ...
                   size(in, 1) == size(in, 2)), ...
           "Balanced assignment problem - must have a square input matrix!");

    % now do the linear program!
    R = size(in, 1);
    C = size(in, 2);

    % first flatten to a vector
    flat = in(:);

    % Now get the equalities. If either the row or column is "exactly-one", then
    % we want the sum to equal exactly 1.
    % These are just linear functionals on our flattened matrix. So, we
    % make a bunch of matrices which have all 1's in just one row (or
    % column), and then flatten them in the same way as the original. Each
    % flattened covector is just a row in our new matrix of equalities
    % (called "Aeq" by MATLAB)

    % Since these matrices are mostly sparse, may as
    % well make them officially sparse.
    % For now, we set Aeq equal to an 0x(R*C) matrix, where R*C is the
    % length of our (flattened) matrix.
    % The rows are (flattened) linear functionals on our (flattened)
    % matrix, with each row representing a different constraint.
    % The "0" for the rows means we start with no constraints, and then
    % just keep adding rows to it.
    % beq is set equal to a 0x1 matrix, which will eventually have its lone
    % column set to the value we want each linear functional to be.
    
    Aeq = sparse(0, R*C);
    beq = sparse(0, 1);

    % do rows first
    if rowcrit == "exactly-one"
        for n=1:R
            % We start with a sparse matrix, which we treat as a linear
            % functional on our original matrix. We set the coefficients to
            % be what we want, and then we flatten it and add it to the
            % matrix.
            % In this situation, we want to make sure that each row has
            % exactly one element. Our convex relaxation is to make sure
            % the entries in each row *sum* to 1 instead, so we'll add
            % that.
            tmp = sparse(R, C);
            tmp(n, :) = 1;          % put all 1's in n'th row, indicating we are summing that row
            Aeq(end+1, :) = tmp(:); % add constraint
        end
        % Now we add "R" different rows to beq, one for each above,
        % saying that we want each linear functional above to evaluate to 1
        % (meaning the sum of each row is 1).
        beq(end+1:end+R, :) = 1;
    end

    % do cols next
    if colcrit == "exactly-one"
        for n=1:C
            % The same as above - for brevity, check the above matrix.
            tmp = sparse(R, C);
            tmp(:, n) = 1;  % set n'th row to 1, then flatten
            Aeq(end+1, :) = tmp(:);
        end
        beq(end+1:end+C, :) = 1;
    end

    % Now get the inequality matrices. If the criterion for rows or cols is
    % "at-most-one", this is basically the same as above, but we're checking if
    % the result of the linear functional maps to less than 1, rather than equal
    % to 1. If it's "at-least-one", we instead negate the linear functional and
    % make sure the result is less than -1.
    A = sparse(0, R*C);
    b = sparse(0, 1);

    % do rows first
    if rowcrit == "at-most-one" || rowcrit == "at-least-one"
        if rowcrit == "at-most-one"
            val = 1;
        else
            val = -1;
        end
        for n=1:R
            tmp = sparse(R, C);
            tmp(n, :) = val;  % set n'th row to 1, then flatten
            A(end+1, :) = tmp(:);
        end
        b(end+1:end+R, :) = val;
    end

    % do cols next
    if colcrit == "at-most-one" || colcrit == "at-least-one"
        if colcrit == "at-most-one"
            val = 1;
        else
            val = -1;
        end
        for n=1:C
            tmp = sparse(R, C);
            tmp(:, n) = val;  % set n'th row to 1, then flatten
            A(end+1, :) = tmp(:);
        end
        b(end+1:end+C, :) = val;
    end

    % We want all entries to be positive, which means we want the lower bound of
    % each variable to be 0 and the upper bound to be 1.
    lb = zeros(size(flat));
    ub = ones(size(flat));

    % Lastly, add a *very small* random linear functional to the objective
    % function, to ensure we always get a unique vertex.
    % We will seed the random number generator to the same thing each time,
    % just to make sure we always get the same results when debugging.
    %%@ this may be better if we multiply by a something infinitesimally
    %%@ distributed near one, since we may have a bunch of zero vector linear
    %%@ functionals
    rng(12345);
    randf = rand(length(flat), 1);
    randf = randf / (1000 * sum(randf));
    rng("shuffle");

    % That's it, run the linear program and reshape back to the original
    % matrix size!
    options = optimset('linprog');
    options.Display = 'off';
    % Negate the sign, since `linprog` minimizes the result, and we want to
    % maximize it
    x = linprog(-(randf + flat), A, b, Aeq, beq, lb, ub, options);
    x = reshape(x, R, C);

    if isempty(x)
        error("No solution to linear program! What kind of constraints were entered?");
    end

    % Just return the matrix x directly, since there may be more than one row
    % assigned to each column and so on
    out = x;
end
