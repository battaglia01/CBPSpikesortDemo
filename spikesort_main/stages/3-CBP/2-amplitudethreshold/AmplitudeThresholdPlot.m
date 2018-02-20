function f = AmplitudeThresholdPlot(disable)
    global params dataobj;
    
    if nargin == 1 & ~disable
        DisableCalibrationTab('Threshold Adjustment');
        return;
    end

    %set local variables
    spike_amps = dataobj.CBPinfo.spike_amps;
    spike_times = dataobj.CBPinfo.spike_times;
    amp_thresholds = dataobj.CBPinfo.amp_thresholds;

    %%@refactored from opts inputparser
    ampbins = params.amplitude.ampbins;
    dt = dataobj.whitening.dt;
    wfnorms = cellfun(@(wf) norm(wf), dataobj.CBPinfo.init_waveforms);
    true_sp = {};
    location_slack = params.postproc.spike_location_slack;%%@is this right?

    % Setup new tab
    AddCalibrationTab('Threshold Adjustment');
    f = GetCalibrationFigure;

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
    for i = 1:n
        subplot(n+1, n, i); cla;

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

    ax  = subplot(n+1, n, sub2ind([n n+1], 1, n+1));
    set(ax, 'Visible', 'off');
    pos = get(ax, 'Position');
    ht = pos(4);
    wsz = get(f, 'Position'); wsz = wsz([3:4]);
    % Add menu item to export thresholds
    %gui_data_export(f, 'amp_thresholds', 'CBP');
    % Add button to export thresholds:
%     uih = uicontrol(f, 'Style', 'pushbutton', ...
%                     'String', 'Use thresholds', ...
%                     'Position', [pos(1), pos(2)+ht/2, pos(3), ht/2].*[wsz,wsz], ...
%                     'Callback', @acceptCallback);
%     uih = uicontrol(f, 'Style', 'pushbutton', ...
%                     'String', 'Revert to default', ...
%                     'Position', [pos(1), pos(2), pos(3), ht/2].*[wsz,wsz], ...
%                     'Callback', @revertCallback);
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
    for i = 1:length(true_sp)
        if isempty(true_sp{i}), continue; end
        subplot(n+1, n, i);
        xlabel(sprintf('misses: %d fps: %d', total_misses(i), total_false_positives(i)));
    end
    return
end

% -----------------
function updateThresh(newthresh, i, f)
    global dataobj;
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
    subplot(n+1, n, sub2ind([n n+1], j, i+2));
    psthxcorr(spiketimes{i}, spiketimes{j})
    title(sprintf('Xcorr, cells %d, %d', i, j));
    if ((i==1) & (j==2)), xlabel('time (sec)'); end
    return
end