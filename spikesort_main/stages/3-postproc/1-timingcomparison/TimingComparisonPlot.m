function TimingComparisonPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Timing Comparison');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    %%@ ORG - could modularize some repeated code shared between this and
    %%@ SpikeTimingPlot
    % set up local vars to reuse
    whitening = CBPdata.whitening;
    true_times = {};
    clustering_times = CBPdata.clustering.spike_times_cl;
    spike_times = CBPdata.waveformrefinement.spike_times_thresholded;
    spike_amps = CBPdata.waveformrefinement.spike_amps_thresholded;
    spike_traces = CBPdata.waveformrefinement.spike_traces_thresholded;
    nchan = size(whitening.data,1);

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

    if isfield(CBPdata.groundtruth, 'true_sp')
        true_times = CBPdata.groundtruth.true_sp;
    end

% -------------------------------------------------------------------------
% Plot Timeseries data (top-left subplot)
    CreateCalibrationTab('Timing Comparison', 'TimingComparison');

    % create axes (if not created already)
    gca;

    % Add whitening traces to plot
    plots = {};
    for n=1:size(whitening.data,1)
        plots{end+1} = [];
        plots{end}.dt = whitening.dt;
        plots{end}.y = whitening.data(n,:)';
        plots{end}.args = {'HandleVisibility', 'off'};
        plots{end}.chan = n+1;
    end

    % Add spike traces to plot
    for n=1:num_cells
        c = plot_cells(n);
        for m=1:size(spike_traces{c},2)
            plots{end+1} = [];
            plots{end}.dt = whitening.dt;
            plots{end}.y = spike_traces{c}(:,m);
            plots{end}.args = {':', 'Color', params.plotting.cell_color(c), ...
                               'LineWidth', 1, 'HandleVisibility', 'off'};
            plots{end}.chan = m+1;
        end
    end

    % Add zero-crossing to plot
    %%@! OPT - this doesn't need to be so many samples!! Could just be
    for n=1:size(whitening.data,1)
        plots{end+1} = [];
        plots{end}.dt = whitening.dt;
        plots{end}.y = zeros(1,size(whitening.data,2));
        plots{end}.args = {'Color', [0 0 0], 'HandleVisibility', 'off'};
        plots{end}.chan = n+1;
    end

    % Add indicators to plot
    for n=1:num_cells
        c = plot_cells(n);
        vertalign = 1-(n-1)/(num_cells-1);
        % CBP indicators
        plots{end+1} = [];
        plots{end}.type = 'rawplot';
        plots{end}.x = (spike_times{c}-1)*whitening.dt;
        plots{end}.y = vertalign*ones(1,length(spike_times{c}));
        plots{end}.args = {'.', 'Color', params.plotting.cell_color(c), ...
                           'MarkerSize', 20, ...
                           'LineWidth', 2, ...
                           'HandleVisibility', 'off'};
                           % , 'DisplayName', ...
                           %['CBP - Spike #' num2str(c)]};
        plots{end}.chan = 'header';

        % Clustering indicators
        plots{end+1} = [];
        plots{end}.type = 'rawplot';
        plots{end}.x = (clustering_times{c}-1)*whitening.dt;
        plots{end}.y = vertalign*ones(1,length(clustering_times{c}));
        plots{end}.args = {'x', 'Color', params.plotting.cell_color(c), ...
                           'MarkerSize', 15, ...
                           'LineWidth', 2, ...
                           'HandleVisibility', 'off'};
                           %, 'DisplayName', ...
                           %['Clustering - Spike #' num2str(c)]};
        plots{end}.chan = 'header';

        % Ground truth indicators
        if ~isempty(true_times)
            plots{end+1} = [];
            plots{end}.type = 'rawplot';
            plots{end}.chan = 'header';
            if c <= length(true_times) && ~isempty(true_times{c})
                plots{end}.x = (true_times{c}-1)*whitening.dt;
                plots{end}.y = vertalign*ones(1,length(true_times{c}));
                plots{end}.args = {'o', 'Color', params.plotting.cell_color(c), ...
                                   'MarkerSize', 10, ...
                                   'LineWidth', 2, ...
                           'HandleVisibility', 'off'};
                                   %, 'DisplayName', ...
                                   %['Truth - Spike #' num2str(c)]};
            else
                plots{end}.x = [NaN];
                plots{end}.y = [NaN];
                plots{end}.args = {'o', 'HandleVisibility', 'off'};
            end
        end
    end

    % Three dummy plots for CBP, clustering, ground truth
    plots{end+1} = [];
    plots{end}.type = 'rawplot';
    plots{end}.chan = 'header';
    plots{end}.x = NaN;
    plots{end}.y = NaN;
    plots{end}.args = {'.', 'Color', 'k', ...
                       'MarkerSize', 15, ...
                       'LineWidth', 2, ...
                       'DisplayName', 'CBP Spike'};

    plots{end+1} = [];
    plots{end}.type = 'rawplot';
    plots{end}.chan = 'header';
    plots{end}.x = NaN;
    plots{end}.y = NaN;
    plots{end}.args = {'x', 'Color', 'k', ...
                       'MarkerSize', 15, ...
                       'LineWidth', 2, ...
                       'DisplayName', 'Clustering Spike'};

    plots{end+1} = [];
    plots{end}.type = 'rawplot';
    plots{end}.chan = 'header';
    plots{end}.x = NaN;
    plots{end}.y = NaN;
    plots{end}.args = {'o', 'Color', 'k', ...
                       'MarkerSize', 15, ...
                       'LineWidth', 2, ...
                       'DisplayName', 'Ground Truth Spike'};


    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);

    multiplotxlabel('Time (sec)');
    multiplottitle("Recovered spikes" + char(10) + "Click 'Cell Plot Info...' for color legend");

    % scale top axis manually
    ax = getappdata(getappdata(gca,'panel'),'mp_axes');
    ylim(ax(1), [-0.5 1.5]);
    %%@ below was useful to avoid auto-resize issues, may not be useful
    %%@ anymore, could probably remove
    multiplotsubignorefunc(@ylim, 1);

    % this seems needed to avoid legend issues
    drawnow;
    pause(0.05);

    lgd = multiplotlegend('Location', 'southoutside', ...
                                'NumColumns', 3, 'FontSize', 10);
    drawnow;
    pause(0.05);
    icons = lgd.EntryContainer.NodeChildren;

    %now resize icons
    for n=1:length(icons)
        icon = icons(n);
        % The following undocumented code changes icon size
        % See: https://undocumentedmatlab.com/blog/plot-legend-customization
        if ~isempty(get(icon.Label,'String'))
            set(icon.Icon.Transform.Children.Children,'Size',10);
        else
            % Remove icon altogether if blank entry (for alignment)
            set(icon.Icon.Transform.Children.Children,'Visible','off')
        end
    end
    text(0.5,0.5,'LOL');
