% This function permutes the waveforms in WaveformRefinement to match those
% in the initial Clustering stage as closely as possible.
%%@ Note: for now, this just uses global variables, but if we need to reuse
%%@ this, we'll just pass the CBPdata object directly
function perm = MatchCBPClusteringWaveforms(init_waveforms, final_waveforms)
global CBPdata params CBPInternals

    % Match new CBP waveforms to clustering waveforms as best as
    % possible. Get normalized versions of flattened waveforms
    new_waveforms_mtx = [];
    for n=1:length(final_waveforms)
        new_waveforms_mtx(:,n) = final_waveforms{n}(:)/norm(final_waveforms{n}(:));
    end
    cluster_waveforms_mtx = [];
    for n=1:length(init_waveforms)
        cluster_waveforms_mtx(:,n) = ...
            init_waveforms{n}(:) / ...
                norm(init_waveforms{n}(:));
    end
    
    % if there are any NaN's, replace with 0's (could happen if a waveform
    % is entirely 0
    new_waveforms_mtx = fillmissing(new_waveforms_mtx, 'constant', 0);
    cluster_waveforms_mtx = fillmissing(cluster_waveforms_mtx, 'constant', 0);

    % now, what we want is to score each waveform pairing based on the norm of
    % the residue if one if projected away from the other (since both have unit
    % norm, this is commutative). It so happens that this is equal to the sine
    % of the angle between them.
    % 
    % If we want to minimize the sum of the squares
    % of these angles, this is minimizing a sum of sines^2, which is
    % equivalent to *maximizing* a sum of (1 - sines^2), which is further equal
    % to maximizing a sum of cosines^2. Since the cosine of the angle is the
    % dot product of the two waveforms, we simply need the assignment that
    % maximizes the sum of squares of all dot products.
    % 
    % first we multiply the matrices together to get these dot products
    % (basically an unnormalized covariance mtx), 
    % then square it pointwise, then run its negation into the linear
    % program (since MATLAB's `linprog` looks for the minimum solution).
    %
    % the rows are CBP waveforms, the cols are clusters, and the resulting
    % permutation is an array of corresponding clusters for each CBP
    % waveforms
    dot_mtx = cluster_waveforms_mtx' * new_waveforms_mtx;
    dot_mtx = dot_mtx.^2;
    if size(dot_mtx, 1) ~= size(dot_mtx, 2)
        % zero pad to a square matrix if need be
        max_ind = max(size(dot_mtx));
        dot_mtx(max_ind, max_ind) = 0;
    end
    perm = BestAssignmentsLinearProgram(-dot_mtx);
    
    % get rid of extra clustering indices
    %%@ maybe better to leave this and change later
%     perm(perm > length(init_waveforms)) = 0;