% Get centroids from the assignments
function centroids = GetCentroids(X, assignments)
N = max(assignments);
centroids = zeros(size(X, 1), N);
for i = 1 : N
    idx = (assignments == i);
    centroids(:, i) = mean(X(:, idx), 2);
end
