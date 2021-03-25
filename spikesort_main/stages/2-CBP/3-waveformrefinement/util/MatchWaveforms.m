% This function permutes the waveforms in WaveformRefinement to match those
% in the initial initing stage as closely as possible.
%%@ Note: for now, this just uses global variables, but if we need to reuse
%%@ this, we'll just pass the CBPdata object directly
function perm = MatchWaveforms(clustering_waveforms, cbp_waveforms)
global CBPdata params CBPInternals

    % We want to match final CBP waveforms to clustering waveforms as best
    % as possible. To do this, we need to first flatten the waveforms and
    % normalize.
    cbp_waveforms_mtx = [];
    for n=1:length(cbp_waveforms)
        cbp_waveforms_mtx(:,n) = cbp_waveforms{n}(:)/norm(cbp_waveforms{n}(:));
    end
    clustering_waveforms_mtx = [];
    for n=1:length(clustering_waveforms)
        clustering_waveforms_mtx(:,n) = ...
            clustering_waveforms{n}(:) / ...
                norm(clustering_waveforms{n}(:));
    end

    % If there are any NaN's, replace with 0's. (could happen if a waveform
    % is entirely 0)
    cbp_waveforms_mtx = fillmissing(cbp_waveforms_mtx, 'constant', 0);
    clustering_waveforms_mtx = fillmissing(clustering_waveforms_mtx, 'constant', 0);

    % Now, what we want is to score each waveform pairing based on the norm of
    % the residue if one if projected away from the other (since both have unit
    % norm, this is commutative). It so happens that this is equal to the sine
    % of the angle between them.
    %
    % If we want to minimize the sum of the squares
    % of these residues, this is minimizing a sum of sines^2, which is
    % equivalent to *maximizing* a sum of (1 - sines^2), which is further equal
    % to maximizing a sum of cosines^2. Since the cosine of the angle is the
    % dot product of the two waveforms, we simply need the assignment that
    % maximizes the sum of squares of all dot products.
    %
    % First we multiply the matrices together to get these dot products
    % (basically an unnormalized covariance mtx),
    % then square it pointwise, then run it into the linear
    % program.
    %
    % The rows are clusters (or "init waveforms") and the cols are the
    % final CBP waveforms. The resulting permutation matrix can be
    % interpreted as a matching of rows(clusters) to columns(CBP waveforms).

    dot_mtx = clustering_waveforms_mtx' * cbp_waveforms_mtx;
    dot_mtx = dot_mtx.^2;
    
    if length(clustering_waveforms) < length(cbp_waveforms)
        % There are more final than init waveforms. In this situation,
        % we started with some N clusters, but then added some in the
        % WaveformRefinement stage.
        %
        % In this situation, we want multiple clusters assigned to one
        % CBP waveform. Since clusters are rows and CBP waveforms are cols,
        % this means we have more cols than rows. We want every col to be
        % mapped to exactly one thing, and we want
        % *at least* one entry in each row (so that some rows can be mapped
        % to multiple columns, aka some clusters can appear twice being
        % mapped to multiple CBP waveforms).
        clustering_crit = "at-least-one";
        cbp_crit = "exactly-one";
    elseif length(clustering_waveforms) > length(cbp_waveforms)
        % More clustering than CBP waveforms. We've perhaps merged two CBP
        % waveforms together, or deleted one.
        %
        % In this situation, we have more rows than cols. This time we want
        % "exactly-one" in each row, and "at-least-one" in each col. This
        % means every cluster is mapped to some CBP waveform (sometimes
        % multiple clusters will be mapped to the same CBP waveform), and
        % each column has *some* cluster mapped to it.
        clustering_crit = "exactly-one";
        cbp_crit = "at-least-one"; %%@ maybe at-most-one?
    else
        % In this situation, there are exactly as many clusters as CBP
        % waveforms, so we just look for the best one-to-one mapping.
        clustering_crit = "exactly-one";
        cbp_crit = "exactly-one";
    end
    perm = BestGeneralizedAssignmentsLinearProgram(dot_mtx, ...
            "RowCriterion", clustering_crit, "ColCriterion", cbp_crit);