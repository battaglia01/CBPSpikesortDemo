% Get centroids from the assignments
function centroids = GetCentroids(X, assignments)
N = max(assignments);
centroids = zeros(size(X, 1), N);
for i = 1 : N
    idx = (assignments == i);
    % if this is empty, just have the centroid be the zero vector. it is
    % this by default given the above initialization, so do nothing if it's
    % empty
    if any(idx)
        centroids(:, i) = mean(X(:, idx), 2);
    end
end
