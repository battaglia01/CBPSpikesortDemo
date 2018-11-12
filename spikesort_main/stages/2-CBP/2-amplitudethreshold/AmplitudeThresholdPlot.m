function AmplitudeThresholdPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('CBP Threshold Adjustment');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    spike_amps = dataobj.CBPinfo.spike_amps;
    spike_times = dataobj.CBPinfo.spike_times;
    amp_thresholds = dataobj.CBPinfo.amp_thresholds;

    f = GetCalibrationFigure;

    %%@refactored from opts inputparser
    ampbins = params.amplitude.ampbins;
    dt = dataobj.whitening.dt;
    wfnorms = cellfun(@(wf) norm(wf), dataobj.CBPinfo.init_waveforms);
    true_sp = {};
    location_slack = params.postproc.spike_location_slack;%%@is this right?

    n = length(spike_amps);
    setappdata(f, 'spikeamps', spike_amps);

    % Store initial thresh value
    if length(amp_thresholds) < length(spike_amps)
        error('Not enough initial thresholds provided.');
    end
    setappdata(f, 'initthresh', amp_thresholds);
    setappdata(f, 'amp_thresholds', amp_thresholds);

    % Modify spiketimes by dt
    spike_times = cellfun(@(st) st.*dt, spike_times,   'UniformOutput', false);
    true_sp    = cellfun(@(st) st.*dt, true_sp, 'UniformOutput', false);
    slack = location_slack*dt;
    setappdata(f, 'spiketimes', spike_times);
    setappdata(f, 'true_sp', true_sp);
    setappdata(f, 'location_slack', slack);

    % Store initial thresholding
    threshspiketimes = cell(size(spike_times));
    for i = 1:n
        threshspiketimes{i} = spike_times{i}(spike_amps{i} > amp_thresholds(i));
    end
    setappdata(f, 'threshspiketimes', threshspiketimes);

    v = ver();
    haveipt = any(strcmp('Image Processing Toolbox', {v.Name}));
    cols = hsv(n);


% -------------------------------------------------------------------------
% Set up new tab and panel
    CreateCalibrationTab('CBP Threshold Adjustment', 'AmplitudeThreshold');

    %compute panel position
    max_n = 4;  %%@magic number, make param later

    p_width = max(n/max_n,1);
    p_height = max((n+1)/(max_n+1),1);

    %add panel to tab
    parent = get(gca,'Parent');
    p = uipanel(parent,...
            'Units','normalized', ...
            'Position',[0 1-p_height p_width p_height], ...
            'Tag', 'amp_panel');

    %create scrollbars
    if n > max_n
        uicontrol('Units','normalized',...
                'Style','Slider',...
                'Position',[.98,.03,.02,.97],...
                'Min',0,...
                'Max',1,...
                'Value',1,...
                'visible','on',...
                'Tag','scrollvert',...
                'Parent',parent,...
                'Callback',@(scr,event) scrollvert);
        uicontrol('Units','normalized',...
                'Style','Slider',...
                'Position',[0,0,.98,.03],...
                'Min',0,...
                'Max',1,...
                'Value',0,...
                'Tag','scrollhoriz',...
                'Parent',parent,...
                'Callback',@(scr,event) scrollhoriz);
    end

% -------------------------------------------------------------------------
% Do all subplotting
    for i = 1:n
        subplot(n+1, n, i, 'Parent', p);
        cla;

        % Plot spike amplitude histogram
        [H, X] = hist(spike_amps{i}, ampbins);
        hh = bar(X,H); set(hh,'FaceColor', cols(i,:), 'EdgeColor', cols(i,:));
        title(sprintf('Amplitudes, cell %d', i));
        xl = [0 max([spike_amps{i}(:); 1.5])];
        xlim(xl);

        if (~isempty(wfnorms))
            X = linspace(0,xl(2),ampbins);
            hold on
            plot(X, max(H)*exp(-((X*wfnorms(i)).^2)/2), 'Color', 0.35*[1 1 1]);
            %        plot(X, max(H)*exp(-(((X-1)*wfnorms(i)).^2)/2), 'Color', cols(i,:));

            hold off
        end

        % Plot threshold as vertical lines.
        hold on;
        yl = get(gca, 'YLim');
        if haveipt
            thresh = amp_thresholds(i);
            xl = get(gca, 'XLim');
            cnstrfcn = makeConstrainToRectFcn('imline', xl, yl);
            lh = imline(gca, thresh*[1 1], yl, ...
                            'PositionConstraintFcn', cnstrfcn);
            lh.setColor('black');
            lch = get(lh, 'Children');
            set(lch(1:2), 'HitTest', 'off');
            set(lh, 'HitTest', 'on');
            set(gca, 'HitTest', 'off');
            %%@ - archived original
            %%@lh.addNewPositionCallback(@(pos) UpdateThresh(pos(1), i, f));
            lh.addNewPositionCallback(@(pos) setappdata(f,['imline_pos_' num2str(i)],pos(1)));
            setappdata(f, ['imline_pos_' num2str(i)], thresh);
        else
            error('ERROR: Must have the Image Processing Toolbox');
        end

        ylim(yl);
    end

    % Plot initial ACorr/XCorrs
    for i = 1:n
        plotACorr(threshspiketimes, i);
        %if(i==1), xlabel('Time (ms)'); end;
        for j = (i+1):n
            plotXCorr(threshspiketimes, i, j);
        end
    end

    % Report on performance relative to ground truth if available
    ShowGroundTruthEval(threshspiketimes, f);

    ax = subplot(n+1, n, sub2ind([n n+1], 1, n+1), 'Parent', p);

    set(ax, 'Visible', 'off');
    pos = get(ax, 'Position');
    ht = pos(4);
    wsz = get(f, 'Position'); wsz = wsz([3:4]);
end

% -----------------
function scrollvert
   scrollbar = findall(GetCalibrationFigure,'Type','uicontrol','Tag','scrollvert');
   panel = findall(GetCalibrationFigure,'Tag','amp_panel');

   pos = get(panel,'Position');
   val = get(scrollbar,'value');

   %%after all is said and done, the above scrolls it correctly
   pos(2) = (1-pos(4))*val;

   set(panel,'Position', pos);
end

% -----------------
function scrollhoriz
   scrollbar = findall(GetCalibrationFigure,'Type','uicontrol','Tag','scrollhoriz');
   panel = findall(GetCalibrationFigure,'Tag','amp_panel');

   pos = get(panel,'Position');
   val = get(scrollbar,'value');

   pos(1) = (1-pos(3))*val;

   set(panel,'Position', pos);
end
