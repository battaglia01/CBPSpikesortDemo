% After clustering, the snippets may be shifted slightly relative to the
% centroids. This realigns the snippets to the centroids, and then
% recomputes the mean - this can be iterated successively for greater
% accuracy.
%
% function [X, XProj, PCs, peak_idx_adj] = ...
%    AdjustSnippetsToCentroid(X, peak_idx, centroids, assignments, nchan, cluster_pars)

function [adj_X, adj_XProj, adj_PCs, adj_centroids, adj_peak_idx] = ...
    AdjustSnippetsToCentroid(whitened_data, X, peak_idx, centroids, ...
                             assignments, nchan, cluster_pars)

% First get the adjusted peak indices
adj_peak_idx = zeros(size(peak_idx));
for n=1:size(X, 2)
    % get the current snippet and centroid
    cur_snippet = X(:, n);
    cur_centroid = centroids(:, assignments(n));

    % to do the xcorr properly, zero pad before flattening and then take a
    % flattened xcorr.
    cur_snippet = reshape(cur_snippet, [], nchan);
    cur_snippet = [cur_snippet;zeros(size(cur_snippet))];
    cur_snippet = cur_snippet(:);

    cur_centroid = reshape(cur_centroid, [], nchan);
    cur_centroid = [cur_centroid;zeros(size(cur_centroid))];
    cur_centroid = cur_centroid(:);

    % now get the optimal lag
    [c lags] = xcorr(cur_centroid, cur_snippet);
    maxlag = lags(min(find(c == max(c))));

    %%@ disable!
    %%@ TURN THIS OFF!
    % maxlag = 0;
    adj_peak_idx(n) = peak_idx(n) + maxlag;
end

% Once we have that, we need to re-sort the indices in case things are
% non-monotonic!
tmp_table = [adj_peak_idx(:) assignments(:)];
tmp_table = sortrows(tmp_table, 1);
adj_peak_idx = tmp_table(:, 1);
assignments = tmp_table(:, 2);

% Once we have that, get the adjusted X snippets and XProj. We do this by
% temporarily setting cluster_pars.alignment_mode to "none" and passing
% that to ConstructSnippetMatrix again.
tmp_pars = cluster_pars;
tmp_pars.alignment_mode = "none";
adj_X = ConstructSnippetMatrix(whitened_data, peak_idx, tmp_pars);

% We also recompute the PC's and so on.
[adj_PCs, adj_XProj] = TruncatePCs(adj_X, cluster_pars.percent_variance);

% Lastly, we get the updated centroids.
%%@ Optional?
adj_centroids = GetCentroids(adj_X, assignments);
