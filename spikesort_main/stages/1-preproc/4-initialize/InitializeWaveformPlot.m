% Calibration for waveform initialization:
% Fig 5 shows the data segments projected onto the first two principal components,
% and the identified clusters.  Fig 6 shows the waveforms associated with each
% cluster.  The visualization function also prints out a table of distances between
% waveforms, and each of their distances to the origin (i.e., their norm).  All
% distances are relative to the noise amplitude.  These numbers provide some
% indication of how likely it is that waveforms could be confused with each other, or
% with background noise.
%
% At this point, waveforms of all potential cells should be identified (NOTE:
% spike identification errors are irrelevant - only the WAVEFORMS matter).  If
% not, may need to adjust params.clustering.num_waveforms and re-run the clustering
% to identify more/fewer cells.  May also wish to adjust the
% params.general.spike_waveform_len, increasing it if the waveforms (Fig 5) are being
% chopped off, or shortening it if there is a substantial boundary region of silence.
% If you do this, you should go back and re-run starting from the whitening step,
% since the waveform_len affects the identification of noise regions.

function InitializeWaveformPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Initial Waveforms, Clusters');
        DeleteCalibrationTab('Initial Waveforms, Shapes');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    % set up local vars
    XProj = CBPdata.clustering.XProj;
    assignments = CBPdata.clustering.assignments;
    X = CBPdata.clustering.X;
    nchan = CBPdata.whitening.nchan;
    dt = CBPdata.whitening.dt;

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

% -------------------------------------------------------------------------
% Plot PCs (Tab 1)
    t = CreateCalibrationTab('Initial Waveforms, Clusters', 'InitializeWaveform');
    cla('reset');
    hold on;

    % X_cluster : time x snippet-index matrix of data
    % XProj_cluster : snippet x PC-component matrix of projections
    % cluster_assignments : vector of class assignments

    X_cluster = CBPdata.clustering.X;
    XProj_cluster = CBPdata.clustering.XProj;
    cluster_assignments = CBPdata.clustering.assignments;

    PlotPCA(X_cluster, XProj_cluster, cluster_assignments);
    title(sprintf('Clustering result (%d clusters, %d plotted)', ...
                  true_num_cells, num_cells));

    % Add merge/split buttons

    % Temporarily set look and feel. Taken from
    % http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');

    splitbutton = uicontrol(t, 'Tag', 'clustering_split', ...
                               'Style', 'pushbutton', ...
                               'FontSize', 14, ...
                               'String', 'Split', ...
                               'Units', 'normalized', ...
                               'Position', [0.75 0 0.125 0.05], ...
                               'Callback', @splitCallback);

    mergebutton = uicontrol(t, 'Tag', 'clustering_merge', ...
                               'Style', 'pushbutton', ...
                               'FontSize', 14, ...
                               'String', 'Merge', ...
                               'Units', 'normalized', ...
                               'Position', [0.875 0 0.125 0.05], ...
                               'Callback', @mergeCallback);

    %Ensure that the controls are fully-rendered before restoring the L&F
    drawnow;
    pause(0.05);

    %Restore original look and feel
    javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);

% -------------------------------------------------------------------------
% Plot the time-domain snippets (Tab 2)
    CreateCalibrationTab('Initial Waveforms, Shapes', 'InitializeWaveform');

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

    % number of cols, rows, and window length
    nc = ceil(sqrt(num_cells));
    nr = ceil((num_cells)/nc);
    wlen = size(X, 1) / nchan;

    %cluster vertical range, maximum number of waveforms to plot
    ylims = zeros(num_cells,2);
    MAX_TO_PLOT = 1e2;

    hold on;
    subplotaxes = {};
    for n = 1:length(plot_cells)
        c = plot_cells(n);
        % X are the individual waveforms. get the subset of X corresponding
        % to the current cluster.
        Xsub = X(:, assignments == c);
        centroid = centroids(:,n);
        if isempty(Xsub)
            continue;
        end

        % If we have more waveforms than the max we want to plot, take a random
        % sample of `MAX_TO_PLOT` waveforms, without replacement
        if (size(Xsub, 2) > MAX_TO_PLOT)
            Xsub = Xsub(:, randsample(size(Xsub, 2), MAX_TO_PLOT, false));
        end

        % Do the plot
        plots = {};
        subplot(nr, nc, n);

        % MATLAB bugfix - by setting the fontsize of the under_panel axes like this
        % in advance, multiplot panel knows to reserve enough space
        set(gca, 'FontSize', 12);

        % do plots
        t_ms = (1:wlen)*dt*1000;
        for m=1:nchan
            plots{end+1} = [];
            plots{end}.x = t_ms;
            plots{end}.y = Xsub((m-1)*wlen+1:m*wlen,:);
            plots{end}.args = {'Color', 0.25*params.plotting.cell_color(c)+0.75*[1 1 1]};
            plots{end}.chan = m;

            plots{end+1} = [];
            plots{end}.x = t_ms;
            plots{end}.y = centroid((m-1)*wlen+1:m*wlen,:);
            plots{end}.args = { 'Color', params.plotting.cell_color(c), 'LineWidth', 2};
            plots{end}.chan = m;
        end

        multiplot(plots);

        % set plot attributes
        multiplotdummyfunc(@set, 'FontSize', 12);   %font for title and labels
        multiplotsubfunc(@set, 'FontSize', 10);     %font for subplot axes
        multiplotsubfunc(@xlim, [0, wlen+1]);       %xlim for subplot axes
        multiplotsubfunc(@axis, 'tight');           %axis tight for subplot axes
        multiplotxlabel('Time (ms)');
        multiplottitle(sprintf('Cell %d, SNR=%.1f', c, norm(centroids(:,n))/sqrt(size(centroids,1))));

        ylims(n,:) = [min(Xsub(:)) max(Xsub(:))];

        % Due to MATLAB subplot(...) display bug, when we try to switch
        % subplots below, it overwrites the original. As a workaround,
        % just save each subplot axes handle in a cell array and do it
        % manually
        subplotaxes{n} = gca;
    end

    % make axis ticks same size on all subplots
    max_ylim = [min(ylims(:,1)) max(ylims(:,2))];
    for n = 1:length(plot_cells)
        c = plot_cells(n);
        % Note above issue with subplot(...) overwrite bug. Do this instead
        % subplot(nr,nc,n); %%@ changed to below, left for reference
        axes(subplotaxes{n});
        multiplotsubfunc(@ylim, max_ylim);
    end

    % write waveform distances
    ip = centroids'*centroids;
    dist2 = repmat(diag(ip),1,size(ip,2)) - 2*ip + repmat(diag(ip)',size(ip,1),1) +...
            diag(diag(ip));
    fprintf(1,'Distances between waveforms (diagonal is norm): \n');
    disp(sqrt(dist2/size(centroids,1)));
end

function mergeCallback(varargin)
    global params;
    dlgtext = inputdlg(['Enter list of clusters to merge (1-' num2str(params.clustering.num_waveforms) '), ' ...
                        'separated by space:'], ...
                        'Merge Clusters');

    if ~isempty(dlgtext)
        try
            to_merge = dlgtext{1};
            to_merge = strrep(to_merge,',',' ');    %just in case they put commas
            to_merge = strsplit(strtrim(to_merge), ' ');
            to_merge = cellfun(@str2num,to_merge);

            MergeClusters(to_merge);
            ChangeCalibrationTab('Initial Waveforms, Clusters');
        catch err
            errordlg(['Invalid clusters! Are you sure you entered a space-delimited list, ' ...
                      'from clusters 1 to ' num2str(params.clustering.num_waveforms) '?']);
        end
    end
end

function splitCallback(varargin)
    global params;
    dlgtext = inputdlg(['Enter cluster to split (1-' num2str(params.clustering.num_waveforms) '):'], ...
                        'Split Clusters');

    if ~isempty(dlgtext)
        try
            to_split = str2num(strtrim(dlgtext{1}));

            dlgtext2 = inputdlg('Enter number of clusters to split into:', 'Split Clusters');
            num_splits = str2num(dlgtext2{1});

            SplitCluster(to_split, num_splits);
            ChangeCalibrationTab('Initial Waveforms, Clusters');
        catch err
            errordlg(['Invalid entry! Are you sure you entered a cluster from ' ...
                      '1 to ' num2str(params.clustering.num_waveforms) ' and a number of splits greater than 0?']);
        end
    end
end
