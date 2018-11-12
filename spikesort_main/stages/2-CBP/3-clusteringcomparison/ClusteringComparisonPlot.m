function ClusteringComparisonPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Clustering Comparison');
        DeleteCalibrationTab('Post-Analysis Waveforms');
        return;
    end


% -------------------------------------------------------------------------
% Set up basics
    %set up local vars - clustering
    nchan = dataobj.whitening.nchan;
    threshold = params.clustering.spike_threshold;
    dt = dataobj.whitening.dt;

    % X : time x snippet-index matrix of data
    % XProj : snippet x PC-component matrix of projections
    % cluster_assignments : vector of class assignments
    X_cluster = dataobj.clustering.X;
    XProj_cluster = dataobj.clustering.XProj;
    cluster_assignments = dataobj.clustering.assignments;

    X_CBP = dataobj.clusteringcomparison.X_CBP;
    XProj_CBP = dataobj.clusteringcomparison.XProj_CBP;
    CBP_assignments = dataobj.clusteringcomparison.CBP_assignments;


    if (~exist('marker', 'var'))
        marker = '.';
    end


% -------------------------------------------------------------------------
% Plot PCs (Repeat of Clustering stage)
    CreateCalibrationTab('Clustering Comparison', 'ClusteringComparison');
    cla('reset');

    subplot(1,2,1);
    hold on;

    num_clusters = max(cluster_assignments);
    colors = hsv(num_clusters);

    cluster_centroids = zeros(size(X_cluster, 1), num_clusters);
    cluster_projCentroids = zeros(size(XProj_cluster,2), num_clusters);
    cluster_counts = zeros(num_clusters, 1);
    cluster_distances = zeros(size(X_cluster,2),1);
    for i=1:num_clusters
        spikeIinds = find(cluster_assignments==i);
        cluster_centroids(:, i) = mean(X_cluster(:, spikeIinds), 2);
        cluster_projCentroids(:,i) = mean(XProj_cluster(spikeIinds,:)', 2);
        cluster_counts(i) = length(spikeIinds);
        cluster_distances(spikeIinds) = sqrt(sum((XProj_cluster(spikeIinds,:)' - ...
           repmat(cluster_projCentroids(:,i),1,cluster_counts(i))).^2))';
    end

    for i=1:num_clusters     %plot central cluster first
        idx = ((cluster_assignments == i) & (cluster_distances<threshold));
        plot(XProj_cluster(idx, 1), XProj_cluster(idx, 2), ...
             '.', 'Color', 0.5*colors(i, :)+0.5*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end
    for i=1:num_clusters     %plot outliers second
        idx = ((cluster_assignments == i) & (cluster_distances>=threshold));
        plot(XProj_cluster(idx, 1), XProj_cluster(idx, 2), ...
             '.', 'Color', 0.5*colors(i, :)+0.5*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end

    cluster_centhandles = [];
    for i=1:num_clusters
      zsc = norm(cluster_projCentroids(:,i));
      cluster_centhandles(i) = plot(cluster_projCentroids(1,i), cluster_projCentroids(2,i), 'o', ...
          'MarkerSize', 9, 'LineWidth', 2, 'MarkerEdgeColor', 'black', ...
          'MarkerFaceColor', colors(i,:), 'DisplayName', ...
          ['Cell ' num2str(i) ', amplitude=' num2str(zsc)]);
    end
    xl = get(gca, 'XLim'); yl = get(gca, 'YLim');
    plot([0 0], yl, '-', 'Color', 0.8 .* [1 1 1]);
    plot(xl, [0 0], '-', 'Color', 0.8 .* [1 1 1]);
    th=linspace(0, 2*pi, 64);
    nh= plot(threshold*sin(th),threshold*cos(th), 'k', 'LineWidth', 2, ...
        'DisplayName', sprintf('Spike threshold = %.1f',threshold));
    legend([nh cluster_centhandles]);
    axis equal;
    hold off;

    set(gca, 'FontSize', 12);
    xlabel('PC 1'); ylabel('PC 2');
    title(sprintf('Clustering result (%d clusters)', num_clusters));


% -------------------------------------------------------------------------
% Plot CBP results on same PCs
    subplot(1,2,2);
    hold on;

    num_CBPspikes = max(CBP_assignments);
    colors = hsv(num_CBPspikes);

    CBP_centroids = zeros(size(X_CBP, 1), num_CBPspikes);
    CBP_projCentroids = zeros(size(XProj_CBP,2), num_CBPspikes);
    CBP_counts = zeros(num_CBPspikes, 1);
    CBP_distances = zeros(size(X_CBP,2),1);
    for i=1:num_CBPspikes
        spikeIinds = find(CBP_assignments==i);
        CBP_centroids(:, i) = mean(X_CBP(:, spikeIinds), 2);
        CBP_projCentroids(:,i) = mean(XProj_CBP(spikeIinds,:)', 2);
        CBP_counts(i) = length(spikeIinds);
        CBP_distances(spikeIinds) = sqrt(sum((XProj_CBP(spikeIinds,:)' - ...
             repmat(CBP_projCentroids(:,i),1,CBP_counts(i))).^2))';
    end

    for i=1:num_CBPspikes     %plot central spike first
        idx = ((CBP_assignments == i) & (CBP_distances<threshold));
        plot(XProj_CBP(idx, 1), XProj_CBP(idx, 2), ...
             '.', 'Color', 0.5*colors(i, :)+0.5*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end
    for i=1:num_CBPspikes     %plot outliers second
        idx = ((CBP_assignments == i) & (CBP_distances>=threshold));
        plot(XProj_CBP(idx, 1), XProj_CBP(idx, 2), ...
             '.', 'Color', 0.5*colors(i, :)+0.5*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end
    CBP_centhandles = [];
    for i=1:num_CBPspikes
      zsc = norm(CBP_projCentroids(:,i));
      CBP_centhandles(i) = plot(CBP_projCentroids(1,i), CBP_projCentroids(2,i), 'o', ...
          'MarkerSize', 9, 'LineWidth', 2, 'MarkerEdgeColor', 'black', ...
          'MarkerFaceColor', colors(i,:), 'DisplayName', ...
          ['Cell ' num2str(i) ', amplitude=' num2str(zsc)]);
    end
    xl = get(gca, 'XLim'); yl = get(gca, 'YLim');
    plot([0 0], yl, '-', 'Color', 0.8 .* [1 1 1]);
    plot(xl, [0 0], '-', 'Color', 0.8 .* [1 1 1]);
    th=linspace(0, 2*pi, 64);
    nh= plot(threshold*sin(th),threshold*cos(th), 'k', 'LineWidth', 2, ...
        'DisplayName', sprintf('Spike threshold = %.1f',threshold));
    legend([nh CBP_centhandles]);
    axis equal;
    hold off;

    set(gca, 'FontSize', 12);
    xlabel('PC 1'); ylabel('PC 2');
    title(sprintf('CBP result (%d CBP spikes)', num_CBPspikes));
