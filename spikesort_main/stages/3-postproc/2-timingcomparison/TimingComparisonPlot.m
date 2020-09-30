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
    spike_time_array_cl = CBPdata.clustering.spike_time_array_cl;
    spike_time_array_cbp = CBPdata.waveformrefinement.spike_time_array_thresholded;
    spike_amps = CBPdata.waveformrefinement.spike_amps_thresholded;
    spike_traces = CBPdata.waveformrefinement.spike_traces_thresholded;
    nchan = size(whitening.data,1);

    
    
    % get permutations - this is the associated cluster/CBP waveform for
    % each ground truth waveform
    best_ordering_cl = CBPdata.groundtruth.best_ordering_cl;
    best_ordering_cbp = CBPdata.groundtruth.best_ordering_cbp;
    
    % we don't want it to plot only ground truth, we also want it to plot
    % CBP and cluster waveforms that have no corresponding ground truth
	% so, neat and simple hackish-way to get it to plot everything, even 
    % if there isn't ground truth there.
    %
    % we pad the permutations with "Inf" if they are different sizes,
    % which, in a sense, matches up any unmatched clusters with CBP "#Inf",
    % and vice versa.
    %
    % This magically causes things to process correctly in the loops below,
    % which, upon running into a "#Inf" waveform, will simply see it is
    % outside the standard clustering/CBP waveform bounds and ignore it
    % (because this logic was built in to handle "unassigned" waveforms
    % which have fake cluster/CBP ID #'s, so this fits into that).
    if length(best_ordering_cl) < length(best_ordering_cbp)
        lendiff = length(best_ordering_cbp) - length(best_ordering_cl);
        best_ordering_cl(end+1:end+lendiff) = Inf;
    elseif length(best_ordering_cl) > length(best_ordering_cbp)
        lendiff = length(best_ordering_cl) - length(best_ordering_cbp);
        best_ordering_cbp(end+1:end+lendiff) = Inf;
    end
    
    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    num_true_cells = length(unique(CBPdata.groundtruth.true_spike_class));
    num_cl_cells = params.clustering.num_waveforms;
    num_cbp_cells = CBPdata.waveformrefinement.num_waveforms;
    num_cells = max([num_true_cells, num_cl_cells, num_cbp_cells]);
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:num_cells);
    num_plot_cells = length(plot_cells);
    CheckPlotCells(num_plot_cells);

    if isfield(CBPdata.groundtruth, 'spike_time_array_processed')
        true_times = CBPdata.groundtruth.spike_time_array_processed;
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
    for n=1:num_plot_cells
        c = plot_cells(n);
        cbp_c = best_ordering_cbp(c);
        
        if cbp_c > length(spike_traces)
            continue;
        end
        
        %%@ WHAT IF NO TRUTH NUMBER? e.g. one waveform is unassigned and it
        %%@ gives it a bogus ID # to represent "unassigned"
        for m=1:size(spike_traces{cbp_c},2)
            plots{end+1} = [];
            plots{end}.dt = whitening.dt;
            plots{end}.y = spike_traces{cbp_c}(:,m);
            plots{end}.args = {':', 'Color', params.plotting.cell_color(cbp_c), ...
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
    for n=1:num_plot_cells
        c = plot_cells(n);
        vertalign = 1-(n-1)/(num_plot_cells-1);
        
        % CBP indicators
        cbp_c = best_ordering_cbp(c);
        if cbp_c <= length(spike_time_array_cbp)
            plots{end+1} = [];
            plots{end}.type = 'rawplot';
            plots{end}.x = (spike_time_array_cbp{cbp_c}-1)*whitening.dt;
            plots{end}.y = vertalign*ones(1,length(spike_time_array_cbp{cbp_c}));
            plots{end}.args = {'.', 'Color', params.plotting.cell_color(c), ...
                               'MarkerSize', 20, ...
                               'LineWidth', 2, ...
                               'HandleVisibility', 'off'};
                               % , 'DisplayName', ...
                               %['CBP - Spike #' num2str(c)]};
            plots{end}.chan = 'header';
        end

        % Clustering indicators
        cl_c = best_ordering_cl(c);
        if cl_c <= length(spike_time_array_cl)
            plots{end+1} = [];
            plots{end}.type = 'rawplot';
            plots{end}.x = (spike_time_array_cl{cl_c}-1)*whitening.dt;
            plots{end}.y = vertalign*ones(1,length(spike_time_array_cl{cl_c}));
            plots{end}.args = {'x', 'Color', params.plotting.cell_color(c), ...
                               'MarkerSize', 15, ...
                               'LineWidth', 2, ...
                               'HandleVisibility', 'off'};
                               %, 'DisplayName', ...
                               %['Clustering - Spike #' num2str(c)]};
            plots{end}.chan = 'header';
        end

        % Ground truth indicators
        tr_c = c;
        if tr_c <= length(true_times)
            plots{end+1} = [];
            plots{end}.type = 'rawplot';
            plots{end}.chan = 'header';
            if tr_c <= length(true_times) && ~isempty(true_times{tr_c})
                plots{end}.x = (true_times{tr_c}-1)*whitening.dt;
                plots{end}.y = vertalign*ones(1,length(true_times{tr_c}));
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
