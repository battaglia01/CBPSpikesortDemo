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
    spike_time_array_cl = CBPdata.ground_truth.clustering.spike_time_array_cl;
    spike_time_array_cbp = CBPdata.waveform_refinement.spike_time_array_thresholded;

    % Get assignment triples that we made in TimingComparisonMain - we will
    % use these to automatically match up the right waveform when plotting
    % things below!
    % Get assignment triples that we made in TimingComparisonMain - we will
    % use these to automatically match up the right waveform when plotting
    % things below!
    assignments = CBPdata.ground_truth.assignments;

    % Get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    if isfield(CBPdata.ground_truth, 'true_spike_class')
        num_true_cells = length(unique(CBPdata.ground_truth.true_spike_class));
    else
        num_true_cells = 0;
    end
    num_cl_cells = params.clustering.num_waveforms;
    num_cbp_cells = CBPdata.waveform_refinement.num_waveforms;
    %%@ NOTE - this was originally the max of the different cells, but now
    %%@ that we're doing it with our "assignments" based method, it should
    %%@ be the length of that instead. Original left for reference
    max_num_cells = length(assignments);
    %%@ max([num_true_cells, num_cl_cells, num_cbp_cells]);
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:max_num_cells);
    num_plot_cells = length(plot_cells);
    CheckPlotCells(num_plot_cells);

    if isfield(CBPdata.ground_truth, 'spike_time_array_processed')
        true_times = CBPdata.ground_truth.spike_time_array_processed;
    else
        true_times = {};
    end

% -------------------------------------------------------------------------
% Plot Timeseries data (top-left subplot)
    CreateCalibrationTab('Timing Comparison', 'TimingComparison');

    % create axes (if not created already)
    gca;

    % Add whitened data to plot
    plots = {};
    for n=1:size(whitening.data,1)
        plots{end+1} = [];
        plots{end}.dt = whitening.dt;
        plots{end}.y = whitening.data(n,:)';
        plots{end}.args = {'HandleVisibility', 'off'};
        plots{end}.chan = n+1;
    end

    % Add reconstructed spike waveform traces to plot.
    % To do this, we first generate all the relevant "Spike Traces" (if
    % they exist):
    %%@ Note, spike_traces_cbp was created previously so we can use that...
    %%@ maybe we should just create all these previously, or else create
    %%@ them all here?
    spike_traces_cl = CBPdata.timing_comparison.spike_traces_cl;
    spike_traces_cbp = CBPdata.timing_comparison.spike_traces_cbp;
    spike_traces_true = CBPdata.timing_comparison.spike_traces_true;

    % To do this, we iterate through our list of assignments, and plot the
    % corresponding traces. If any assignment is "0" we skip it, or if it's
    % a vector of multiple values, we add the traces together. No CBP or
    % clustering waveform should ever appear twice, due to the way we coded
    % TimingComparisonMain.
    for n=1:length(assignments)
        cur_assignment = assignments{n};

        % Build ground truth trace, if it exists
        cur_true = cur_assignment.true;
        if cur_true > 0 && cur_true <= num_true_cells
            for m=1:size(spike_traces_true{cur_true},2)
                plots{end+1} = [];
                plots{end}.dt = whitening.dt;
                plots{end}.y = spike_traces_true{cur_true}(:,m);
                plots{end}.args = {'-', 'Color', params.plotting.cell_color(n), ...
                                   'LineWidth', 1, 'HandleVisibility', 'off'};
                plots{end}.chan = m+1;
            end
        end

        % Build CBP trace, if it exists
        cur_cbp_all = cur_assignment.cbp;
        for o=1:length(cur_cbp_all)
            cur_cbp = cur_cbp_all(o);
            if cur_cbp > 0 && cur_cbp <= num_cbp_cells
                for m=1:size(spike_traces_cbp{cur_cbp},2)
                    plots{end+1} = [];
                    plots{end}.dt = whitening.dt;
                    plots{end}.y = spike_traces_cbp{cur_cbp}(:,m);
                    plots{end}.args = {'-.', 'Color', params.plotting.cell_color(n), ...
                                       'LineWidth', 1, 'HandleVisibility', 'off'};
                    plots{end}.chan = m+1;
                end
            end
        end

        % Build clustering trace, if it exists
        cur_cl_all = cur_assignment.cl;
        for o=1:length(cur_cl_all)
            cur_cl = cur_cl_all(o);
            if cur_cl > 0 && cur_cl <= num_cl_cells
                for m=1:size(spike_traces_cl{cur_cl},2)
                    plots{end+1} = [];
                    plots{end}.dt = whitening.dt;
                    plots{end}.y = spike_traces_cl{cur_cl}(:,m);
                    plots{end}.args = {':', 'Color', params.plotting.cell_color(n), ...
                                       'LineWidth', 1, 'HandleVisibility', 'off'};
                    plots{end}.chan = m+1;
                end
            end
        end
    end

    % Add zero-crossing to plot
    for n=1:size(whitening.data,1)
        plots{end+1} = [];
    %%@! OPT - just add two samples at (0,0) and (nsamples,0) and let
    %%@ MATLAB fill in the rest
        plots{end}.dt = whitening.dt;
        plots{end}.y = zeros(1,size(whitening.data,2));
        plots{end}.args = {'Color', [0 0 0], 'HandleVisibility', 'off'};
        plots{end}.chan = n+1;
    end

    % Add indicators to plot.
    % To do this, we iterate through our list of assignments, and plot the
    % corresponding traces. If any assignment is "0" we skip it, or if it's
    % a vector of multiple values, we add the traces together. No CBP or
    % clustering waveform should ever appear twice, due to the way we coded
    % TimingComparisonMain.
    for n=1:length(assignments)
        vertalign = 1-(n-1)/(num_plot_cells-1);
        cur_assignment = assignments{n};

        % Plot ground truth indicators, if they exist
        cur_true = cur_assignment.true;
        % check if index is valid
        if cur_true > 0 && cur_true <= num_true_cells
            plots{end+1} = [];
            plots{end}.type = 'rawplot';
            plots{end}.x = (true_times{cur_true}-1)*whitening.dt;
            plots{end}.y = vertalign*ones(1,length(true_times{cur_true}));
            plots{end}.args = {'x', 'Color', params.plotting.cell_color(n), ...
                               'MarkerSize', 10, ...
                               'LineWidth', 2, ...
                               'HandleVisibility', 'off'};
                               %, 'DisplayName', ...
                               %['Truth - Spike #' num2str(c)]};
            plots{end}.chan = 'header';
        end

        % Plot CBP indicators, if they exist
        cur_cbp_all = cur_assignment.cbp;
        % if so, iterate on all cbp indices
        for o=1:length(cur_cbp_all)
            cur_cbp = cur_cbp_all(o);
            % check if index is valid
            if cur_cbp > 0 && cur_cbp <= num_cbp_cells
                plots{end+1} = [];
                plots{end}.type = 'rawplot';
                plots{end}.x = (spike_time_array_cbp{cur_cbp}-1)*whitening.dt;
                plots{end}.y = vertalign*ones(1,length(spike_time_array_cbp{cur_cbp}));
                plots{end}.args = {'.', 'Color', params.plotting.cell_color(n), ...
                                   'MarkerSize', 20, ...
                                   'LineWidth', 2, ...
                                   'HandleVisibility', 'off'};
                                   % , 'DisplayName', ...
                                   %['CBP - Spike #' num2str(c)]};
                plots{end}.chan = 'header';
            end
        end

        % Build clustering trace, if it exists
        cur_cl_all = cur_assignment.cl;
        % if so, iterate on all cbp indices
        for o=1:length(cur_cl_all)
            cur_cl = cur_cl_all(o);
            if cur_cl > 0 && cur_cl <= num_cl_cells
                plots{end+1} = [];
                plots{end}.type = 'rawplot';
                plots{end}.x = (spike_time_array_cl{cur_cl}-1)*whitening.dt;
                plots{end}.y = vertalign*ones(1,length(spike_time_array_cl{cur_cl}));
                plots{end}.args = {'o', 'Color', params.plotting.cell_color(n), ...
                                   'MarkerSize', 15, ...
                                   'LineWidth', 2, ...
                                   'HandleVisibility', 'off'};
                                   %, 'DisplayName', ...
                                   %['Clustering - Spike #' num2str(c)]};
                plots{end}.chan = 'header';
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
    plots{end}.args = {'o', 'Color', 'k', ...
                       'MarkerSize', 15, ...
                       'LineWidth', 2, ...
                       'DisplayName', 'Clustering Spike'};

    %%@ CHECK IF THIS EXISTS?
    plots{end+1} = [];
    plots{end}.type = 'rawplot';
    plots{end}.chan = 'header';
    plots{end}.x = NaN;
    plots{end}.y = NaN;
    plots{end}.args = {'x', 'Color', 'k', ...
                       'MarkerSize', 15, ...
                       'LineWidth', 2, ...
                       'DisplayName', 'Ground Truth Spike'};


    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);

    multiplotxlabel('Time (sec)');
    multiplottitle("Recovered spikes" + newline + "Click 'Cell Plot Info...' for color legend");

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
                                'NumColumns', 3);
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
