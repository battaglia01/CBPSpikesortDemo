% Plots the PCA. Used in both InitializeWaveform and ClusteringComparison plots

% X : time x snippet-index matrix of data
% XProj : snippet x PC-component matrix of projections
% assignments : vector of class assignments

function PlotPCA(X, XProj, assignments)
    global CBPdata params CBPInternals;

% -------------------------------------------------------------------------
% Set up basics
    %set up local vars
    nchan = CBPdata.whitening.nchan;
    threshold = params.clustering.spike_threshold;
    dt = CBPdata.whitening.dt;

    marker = '.';

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

    % only compute centroids, projCentroids, etc for the cells being plotted.
    % note that the n'th column index corresponds to the cell `plot_cells(n)`, not just `n`.
    centroids = zeros(size(X, 1), num_cells);
    projCentroids = zeros(size(XProj,2), num_cells);
    counts = zeros(num_cells, 1);
    distances = zeros(size(X, 2),1);
    for n=1:length(plot_cells)
      spikeInds = find(assignments==plot_cells(n));
      centroids(:, n) = mean(X(:, spikeInds), 2);
      projCentroids(:, n) = mean(XProj(spikeInds,:)', 2);
      counts(n) = length(spikeInds);
      distances(spikeInds) = sqrt(sum((XProj(spikeInds,:)' - ...
           repmat(projCentroids(:,n),1,counts(n))).^2))';     %%@ RMS - RSS
    end

% -------------------------------------------------------------------------
% Now plot in current plot
    cla('reset');
    hold on;

    % First plot central cluster
    for n=1:length(plot_cells)
        c = plot_cells(n);
        idx = ((assignments == c) & (distances<threshold));
        plot(XProj(idx, 1), XProj(idx, 2), ...
             '.', 'Color', 0.75*params.plotting.cell_color(c)+0.25*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end

    % Then plot outliers
    for n=1:length(plot_cells)
        c = plot_cells(n);
        idx = ((assignments == c) & (distances>=threshold));
        plot(XProj(idx, 1), XProj(idx, 2), ...
             '.', 'Color', 0.75*params.plotting.cell_color(c)+0.25*[1 1 1], ...
             'Marker', marker, 'MarkerSize', 8);
    end

    % Then plot centroid markers
    centhandles = [];
    for n=1:length(plot_cells)
        c = plot_cells(n);
        zsc = norm(projCentroids(:,n));
        centhandles(n) = plot(projCentroids(1,n), projCentroids(2,n), 'o', ...
          'MarkerSize', 9, 'LineWidth', 2, 'MarkerEdgeColor', 'black', ...
          'MarkerFaceColor', params.plotting.cell_color(c), 'DisplayName', ...
          ['Cell ' num2str(c) ', amplitude=' num2str(zsc)]);
    end

    % plot coordinate axes
    xl = get(gca, 'XLim'); yl = get(gca, 'YLim');
    plot([0 0], yl, '-', 'Color', 0.8 .* [1 1 1]);
    plot(xl, [0 0], '-', 'Color', 0.8 .* [1 1 1]);

    % plot spike threshold circle
    th=linspace(0, 2*pi, 64);
    nh= plot(threshold*sin(th),threshold*cos(th), 'k', 'LineWidth', 2, ...
        'DisplayName', sprintf('Spike threshold = %.1f',threshold));

    % now set legend, axes, fonts, labels, title
    hold off;
    legend([nh centhandles]);
    axis equal;
    set(gca, 'FontSize', 12);
    xlabel('PC 1');
    ylabel('PC 2');
    %title(sprintf('Clustering result (%d clusters)', num_cells));

end
