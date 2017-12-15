%%@ WHY on the PC representation?!?
% Do K-means clustering on the PC representation of the snippets
function assignments = DoKMeans(Xproj, nwaveforms)
fprintf('Clustering using k-means...\n');

% Number of times to try with random initialization
num_reps = 25;

% Use default K-means settings for now.
distance_mode = 'sqEuclidean';
start_mode = 'sample'; % centroid initialization = random sample
empty_mode = 'error'; % throw error when clusters are empty
opts = statset('MaxIter', 1e3);
% Run K-means, from stat toolbox
assignments = kmeans(Xproj, nwaveforms,...
    'Replicates', num_reps, ...
    'Distance', distance_mode, ...
    'Start', start_mode, ...
    'EmptyAction', empty_mode, ...
    'Options', opts);
fprintf('Done.\n');
