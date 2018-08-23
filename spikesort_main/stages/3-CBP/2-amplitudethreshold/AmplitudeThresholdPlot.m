function f = AmplitudeThresholdPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DisableCalibrationTab('Threshold Adjustment');
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
% Set up new tab and panel %%@ -- all mike
    AddCalibrationTab('Threshold Adjustment');
    
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
            xl = get(gca, 'XLim');
            cnstrfcn = makeConstrainToRectFcn('imline', xl, yl);
            lh = imline(gca, amp_thresholds(i)*[1 1], yl, 'PositionConstraintFcn', cnstrfcn);
            lh.setColor('black');
            lch = get(lh, 'Children');
            set(lch(1:2), 'HitTest', 'off');
            set(lh, 'HitTest', 'on');
            set(gca, 'HitTest', 'off');
            lh.addNewPositionCallback(@(pos) updateThresh(pos(1), i, f));
        else
            plot(thresh(i) * [1 1], yl, 'Color', cols(i,:), 'LineWidth', 2);
        end

        ylim(yl);
    end
    
    % Plot initial ACorr/XCorrs
    for i = 1:n
        plotACorr(threshspiketimes, i);
        %    if(i==1), xlabel('time (sec)'); end;
        for j = (i+1):n
            plotXCorr(threshspiketimes, i, j);
        end
    end

    % Report on performance relative to ground truth if available
    showGroundTruthEval(threshspiketimes, f);

    ax = subplot(n+1, n, sub2ind([n n+1], 1, n+1), 'Parent', p);
    
    set(ax, 'Visible', 'off');
    pos = get(ax, 'Position');
    ht = pos(4);
    wsz = get(f, 'Position'); wsz = wsz([3:4]);
    return
end

% -----------------
function acceptCallback(hObject, eventdata)
  global dataobj;
  ampthresh = getappdata(gcbf, 'amp_thresholds');
  dataobj.CBPinfo.amp_thresholds = ampthresh;
  return
end

% -----------------
function revertCallback(hObject, eventdata)
  global dataobj;
  initthresh = getappdata(gcbf, 'initthresh');
  dataobj.CBPinfo.amp_thresholds = initthresh;
  for i=1:length(getappdata(gcbf, 'amp_thresholds'))
      updateThresh(initthresh(i), i, gcbf);
  end
  return
end

% -----------------
function showGroundTruthEval(spiketimes, f)
    true_sp = getappdata(f, 'true_sp');
    if isempty(true_sp), return; end
    slack = getappdata(f, 'location_slack');

    % Evaluate CBP sorting
    [total_misses, total_false_positives] = ...
        evaluate_sorting(spiketimes, true_sp, slack);

    % Display on fig
    n = length(spiketimes);
    p = findall(gcf,'Tag','amp_panel');
    
    for i = 1:length(true_sp)
        if isempty(true_sp{i}), continue; end
        subplot(n+1, n, i, 'Parent', p);
        xlabel(sprintf('misses: %d fps: %d', total_misses(i), total_false_positives(i)));
    end
    return
end

% -----------------
function updateThresh(newthresh, i, f)
    global dataobj;
    if CalibrationTabExists('Waveform Review')
        UpdateStage(@AmplitudeThresholdStage,false);   %doesn't clear current
    end
    
    threshsts = getappdata(f, 'threshspiketimes');
    sts       = getappdata(f, 'spiketimes');
    amps      = getappdata(f, 'spikeamps');

    % Calculate new threshed sts
    threshsts{i} = sts{i}(amps{i} > newthresh);

    % Plot
    plotACorr(threshsts, i);
    n = length(threshsts);
    for j = (i+1):n
        plotXCorr(threshsts, i, j);
    end

    showGroundTruthEval(threshsts, f);

    % Save new threshes and threshed spiketimes
    setappdata(f, 'threshspiketimes', threshsts);
    amp_thresholds = getappdata(f, 'amp_thresholds');
    amp_thresholds(i) = newthresh;
	dataobj.CBPinfo.amp_thresholds = amp_thresholds;
    setappdata(f, 'amp_thresholds', amp_thresholds);
    return
end

% -----------------
function plotACorr(spiketimes, i)
    n = length(spiketimes);
    p = findall(gcf,'Tag','amp_panel');
    
    subplot(n+1, n, sub2ind([n n+1], i, 2));
    psthacorr(spiketimes{i})
    title(sprintf('Autocorr, cell %d', i));
    if (i==1), xlabel('time (sec)'); end
    return
end

% -----------------
function plotXCorr(spiketimes, i, j)
    if j < i
        tmp = i;
        i = j;
        j = tmp;
    end
    n = length(spiketimes);
    p = findall(gcf,'Tag','amp_panel');
    
    subplot(n+1, n, sub2ind([n n+1], j, i+2));
    psthxcorr(spiketimes{i}, spiketimes{j})
    title(sprintf('Xcorr, cells %d, %d', i, j));
    if ((i==1) & (j==2)), xlabel('time (sec)'); end
    return
end

% -----------------
function scrollvert
   scrollbar = findall(gcf,'Type','uicontrol','Tag','scrollvert');
   panel = findall(gcf,'Tag','amp_panel');

   pos = get(panel,'Position');
   val = get(scrollbar,'value');
   
   %%after all is said and done, the above scrolls it correctly
   pos(2) = (1-pos(4))*val;
   
   set(panel,'Position', pos);
end % end scrollvert

% -----------------
function scrollhoriz
   scrollbar = findall(gcf,'Type','uicontrol','Tag','scrollhoriz');
   panel = findall(gcf,'Tag','amp_panel');

   pos = get(panel,'Position');
   val = get(scrollbar,'value');
  
   pos(1) = (1-pos(3))*val;
   
   set(panel,'Position', pos);
end % end scrollhoriz