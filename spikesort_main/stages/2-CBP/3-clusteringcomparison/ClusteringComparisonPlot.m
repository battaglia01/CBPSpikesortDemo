function ClusteringComparisonPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Clustering Comparison');
        DeleteCalibrationTab('Post-Analysis Waveforms');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

% -------------------------------------------------------------------------
% Plot PCs (Repeat of Clustering stage)

    CreateCalibrationTab('Clustering Comparison', 'ClusteringComparison');
    cla('reset');

    % X_cluster : time x snippet-index matrix of data
    % XProj_cluster : snippet x PC-component matrix of projections
    % cluster_assignments : vector of class assignments

    X_cluster = CBPdata.clustering.X;
    XProj_cluster = CBPdata.clustering.XProj;
    cluster_assignments = CBPdata.clustering.assignments;

    subplot(1,2,1);
    PlotPCA(X_cluster, XProj_cluster, cluster_assignments);
    title(sprintf('Clustering result (%d clusters, %d plotted)', ...
                  true_num_cells, num_cells));

	axis1 = gca;
    axis1_x = xlim;
    axis1_y = ylim;

% -------------------------------------------------------------------------
% Plot CBP results on same PCs

    % X_CBP : time x snippet-index matrix of data
    % XProj_CBP : snippet x PC-component matrix of projections
    % CBP_assignments : vector of class assignments

    X_CBP = CBPdata.clusteringcomparison.X_CBP;
    XProj_CBP = CBPdata.clusteringcomparison.XProj_CBP;
    CBP_assignments = CBPdata.clusteringcomparison.CBP_assignments;

    subplot(1,2,2);
    PlotPCA(X_CBP, XProj_CBP, CBP_assignments);
    title(sprintf('CBP result (%d CBP spike types, %d plotted)', ...
                  true_num_cells, num_cells));

    axis2 = gca;
    axis2_x = xlim;
    axis2_y = ylim;

% -------------------------------------------------------------------------
% Synchronize axes

    axis_xmax = [];
    axis_xmax(1) = min([axis1_x(1);axis2_x(1)]);
    axis_xmax(2) = max([axis1_x(2);axis2_x(2)]);

    axis_ymax = [];
    axis_ymax(1) = min([axis1_y(1);axis2_y(1)]);
    axis_ymax(2) = max([axis1_y(2);axis2_y(2)]);

    xlim(axis1, axis_xmax);
    ylim(axis1, axis_ymax);
    xlim(axis2, axis_xmax);
    ylim(axis2, axis_ymax);
