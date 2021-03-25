% Fig7 allows interactive adjustment of waveform amplitudes, while visualizing effect
% on spike train auto- and cross-correlations.  Top row shows amplitude distribution
% (typical spikes should have amplitude 1), with expected (Gaussian) noise
% distribution at left, and thresholds indicated by vertical lines.  Threshold lines
% can be mouse-dragged right or left.  Next row shows spike train autocorrelation
% that would result from chosen threshold, and can be examined for refractory
% violations.  Bottom rows show spike train cross-correlations across pairs of cells,
% and can be examined for dropped synchronous spikes (very common with clustering
% methods).  Click the "Use thresholds" button to proceed with the chosen values.
% Click the "Revert" button to revert to the automatically-chosen default values.

function AmplitudeThresholdPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('CBP Threshold Adjustment');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    spike_amps = CBPdata.CBP.spike_amps;
    spike_time_array_ms = CBPdata.CBP.spike_time_array_ms;
    amp_thresholds = CBPdata.amplitude.amp_thresholds;

    f = GetCalibrationFigure;

    ampbins = params.amplitude.ampbins;
    dt = CBPdata.whitening.dt;
    wfnorms = cellfun(@(wf) norm(wf), CBPdata.CBP.init_waveforms);
    spike_time_array_processed = CBPdata.amplitude.spike_time_array_processed;
    location_slack = params.amplitude.spike_location_slack;

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = CBPdata.CBP.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

    % Store initial thresh value
    if length(amp_thresholds) < length(spike_amps)
        error('Not enough initial thresholds provided.');
    end

    % Modify spiketimes by dt
    spike_time_array_processed = cellfun(@(st) st.*dt, spike_time_array_processed, 'UniformOutput', false);
    slack = location_slack*dt;

    % Store initial thresholding
    threshspiketimes = cell(size(spike_time_array_ms));
    for n=1:num_cells
        c = plot_cells(n);
        threshspiketimes{c} = spike_time_array_ms{c}(spike_amps{c} > amp_thresholds(c));
    end
    CBPdata.amplitude.thresh_spike_time_array_ms = threshspiketimes;

% -------------------------------------------------------------------------
% Set up new tab and panel
    t = CreateCalibrationTab('CBP Threshold Adjustment', 'AmplitudeThreshold');

    %compute panel position
    max_n = params.amplitude.maxplotsbeforescroll;
    p_width = max(num_cells/max_n,1);
    p_height = max((num_cells+1)/(max_n+1),1);
    p_left = (1-p_width)/7;           % empirically, this works well
    p_bottom = 1-p_height-p_left/2;   % empirically, this also works well

    %add panel to tab
    parent = get(gca,'Parent');
    inner_panel = uipanel(parent,...
                'Units','normalized', ...
                'Position',[p_left p_bottom p_width p_height], ...
                'Tag', 'amp_panel');
    RegisterTag(inner_panel);
    
%     loading = uicontrol(t, 'Style', 'Text', ...
%                  'FontUnits', 'normalized', ...
%                  'FontSize', 0.2, ...
%                  'Units', 'normalized', ...
%                  'Position', [0.333 0.8 0.333 0.2], ...
%                  'String', 'Loading...');
	drawnow;
    pause(0.001);

    %create scrollbars
%     scrollleft = 1/7;
%     scrollright = 1 - scrollleft/2;
%     scrollbottom = (1-p_height-p_left/2)/(1-p_height);
%     scrolltop = 1 - scrollbottom;
    if num_cells <= max_n
        scroll_type = "none";
    else
        scroll_type = "both";
    end
    horiz_offset = (p_width - 1) + p_left*1.75;% + 2*p_left;
    vert_offset = (p_height - 1) + 1.75*p_left/2;
    scroll_panel = uiscrollpanel(inner_panel, scroll_type, horiz_offset, vert_offset);
                 

% -------------------------------------------------------------------------
% Do all subplotting
    for n=1:num_cells
        c = plot_cells(n);
        subplot(num_cells+1, num_cells, n, 'Parent', inner_panel);
        cla;

        % Plot spike amplitude histogram
        if length(spike_amps{c}) ~= 1
            [H, X] = hist(spike_amps{c}, ampbins);
        else
            [H, X] = hist(spike_amps{c}, spike_amps{c}(1) + linspace(-.5,.5,50));
        end
        hh = bar(X, H);
        set(hh, 'FaceColor', params.plotting.cell_color(c), ...
                'EdgeColor', params.plotting.cell_color(c));
        title(sprintf('Amplitudes, cell %d', c));
        xl = [0 max([spike_amps{c}(:); 1.5])];
        xlim(xl);

        % Plot Gaussian on each subplot
        if (~isempty(wfnorms))
            X = linspace(0,xl(2),ampbins);
            hold on;
            plot(X, max(H)*exp(-((X*wfnorms(c)).^2)/2), 'Color', 0.35*[1 1 1]);
            hold off;
        end

        % Plot threshold as vertical lines.
        % Make sure we have the Image Processing Toolbox
        v = ver();
        haveipt = any(strcmp('Image Processing Toolbox', {v.Name}));
        if haveipt
            thresh = amp_thresholds(c);
            yl = get(gca, 'YLim');
            xl = get(gca, 'XLim');
            cnstrfcn = makeConstrainToRectFcn('imline', xl, yl);

            hold on;
            lh = imline(gca, thresh*[1 1], yl, ...
                             'PositionConstraintFcn', cnstrfcn);
            lh.setColor('black');
            lch = get(lh, 'Children');
            set(lch(1:2), 'HitTest', 'off');
            set(lh, 'HitTest', 'on');
            set(gca, 'HitTest', 'off');
            lh.addNewPositionCallback(@(pos) setappdata(f,['imline_pos_' num2str(c)],pos(1)));
            setappdata(f, ['imline_pos_' num2str(c)], thresh);

            hold off;
        else
            error('ERROR: Must have the Image Processing Toolbox');
        end

        ylim(yl);
    end

    % Plot initial ACorr/XCorrs
    for n=1:num_cells
        c = plot_cells(n);
        PlotACorr(threshspiketimes, num_cells, n);
        for m = (n+1):num_cells
            PlotXCorr(threshspiketimes, num_cells, n, m);
        end
    end
%     delete(loading);
    pause(0.01);
    drawnow;
            
    % Report on performance relative to ground truth if available
    ShowGroundTruthEval(threshspiketimes, f);

    ax = subplot(num_cells+1, num_cells, ...
                 sub2ind([num_cells num_cells+1], 1, num_cells+1), 'Parent', inner_panel);

    set(ax, 'Visible', 'off');
    pos = get(ax, 'Position');
    ht = pos(4);
    wsz = get(f, 'Position'); wsz = wsz([3:4]);
end
