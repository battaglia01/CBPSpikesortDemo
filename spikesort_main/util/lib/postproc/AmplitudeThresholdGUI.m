<<<<<<< HEAD:spikesort_main/util/lib/postproc/AmplitudeThresholdGUI.m
function f = AmplitudeThresholdGUI(spikeamps, spiketimes, initthresh, varargin)
global params dataobj;
opts = inputParser();
opts.addParamValue('f', []);
opts.addParamValue('ampbins', 60);
%opts.addParamValue('fontsize', 16);
opts.addParamValue('dt', 1);
opts.addParamValue('wfnorms', []);
opts.addParamValue('true_sp', {});
opts.addParamValue('location_slack', 30); % Allowed mismatch in timing for comparison to ground truth
opts.parse(varargin{:});
opts = opts.Results;

% Setup figure
f = opts.f;
if isempty(f)
  f = figure(132973478);  %%@magic number but no biggie
  clf(f,'reset');
  scrsz =  get(0,'ScreenSize');  %maximizes
  set(gcf, 'OuterPosition', [0.05*scrsz(3) 0.10*scrsz(4) .9*scrsz(3) .85*scrsz(4)]);
  f.NumberTitle = 'off';
  f.Name = 'Threshold Visualization';
else
  figure(f);
  clf(f,'reset');
  scrsz =  get(0,'ScreenSize');  %maximizes
  set(gcf, 'OuterPosition', [0.05*scrsz(3) 0.10*scrsz(4) .9*scrsz(3) .85*scrsz(4)]);
end

n = length(spikeamps);
setappdata(f, 'spikeamps', spikeamps);

% Store initial thresh value
if length(initthresh) < length(spikeamps)
    error('Not enough initial thresholds provided.');
end
setappdata(f, 'initthresh', initthresh);
setappdata(f, 'amp_thresholds', initthresh);

% Modify spiketimes by dt
spiketimes = cellfun(@(st) st.*opts.dt, spiketimes,   'UniformOutput', false);
true_sp    = cellfun(@(st) st.*opts.dt, opts.true_sp, 'UniformOutput', false);
slack = opts.location_slack*opts.dt;
setappdata(f, 'spiketimes', spiketimes);
setappdata(f, 'true_sp', true_sp);
setappdata(f, 'location_slack', slack);

% Store initial thresholding
threshspiketimes = cell(size(spiketimes));
for i = 1:n
    threshspiketimes{i} = spiketimes{i}(spikeamps{i} > initthresh(i));
end
setappdata(f, 'threshspiketimes', threshspiketimes);

v = ver();
haveipt = any(strcmp('Image Processing Toolbox', {v.Name}));
cols = hsv(n);
for i = 1:n
    subplot(n+1, n, i); cla;

    % Plot spike amplitude histogram
    [H, X] = hist(spikeamps{i}, opts.ampbins);
    hh = bar(X,H); set(hh,'FaceColor', cols(i,:), 'EdgeColor', cols(i,:));
    title(sprintf('Amplitudes, cell %d', i));
    xl = [0 max([spikeamps{i}(:); 1.5])];
    xlim(xl);

    if (~isempty(opts.wfnorms))
        X = linspace(0,xl(2),opts.ampbins);
        hold on
        plot(X, max(H)*exp(-((X*opts.wfnorms(i)).^2)/2), 'Color', 0.35*[1 1 1]);
        %        plot(X, max(H)*exp(-(((X-1)*opts.wfnorms(i)).^2)/2), 'Color', cols(i,:));

        hold off
    end

    % Plot threshold as vertical lines.
    hold on;
    yl = get(gca, 'YLim');
    if haveipt
        xl = get(gca, 'XLim');
        cnstrfcn = makeConstrainToRectFcn('imline', xl, yl);
        lh = imline(gca, initthresh(i)*[1 1], yl, 'PositionConstraintFcn', cnstrfcn);
        lh.setColor('black');
        lch = get(lh, 'Children');
        set(lch(1:2), 'HitTest', 'off');
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
uih = uicontrol(f, 'Style', 'pushbutton', ...
                'String', 'Use thresholds', ...
                'Position', [pos(1), pos(2)+ht/2, pos(3), ht/2].*[wsz,wsz], ...
                'Callback', @acceptCallback);
uih = uicontrol(f, 'Style', 'pushbutton', ...
                'String', 'Revert to default', ...
                'Position', [pos(1), pos(2), pos(3), ht/2].*[wsz,wsz], ...
                'Callback', @revertCallback);

% if nargout < 1, clear f; end
return

% -----------------
function acceptCallback(hObject, eventdata)
  global dataobj;
  ampthresh = getappdata(gcbf, 'amp_thresholds');
  dataobj.CBPinfo.amp_thresholds = ampthresh;
  return

% -----------------
function revertCallback(hObject, eventdata)
  global dataobj;
  initthresh = getappdata(gcbf, 'initthresh');
  dataobj.CBPinfo.amp_thresholds = initthresh;
  for i=1:length(getappdata(gcbf, 'amp_thresholds'))
      updateThresh(initthresh(i), i, gcbf);
  end
  return

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

% -----------------
function updateThresh(newthresh, i, f)
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
setappdata(f, 'amp_thresholds', amp_thresholds);
return

% -----------------
function plotACorr(spiketimes, i)
n = length(spiketimes);
subplot(n+1, n, sub2ind([n n+1], i, 2));
psthacorr(spiketimes{i})
title(sprintf('Autocorr, cell %d', i));
if (i==1), xlabel('time (sec)'); end
return

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
=======
function f = AmplitudeThresholdGUI(spikeamps, spiketimes, initthresh, varargin)
global params dataobj;
opts = inputParser();
opts.addParamValue('f', []);
opts.addParamValue('ampbins', 60);
%opts.addParamValue('fontsize', 16);
opts.addParamValue('dt', 1);
opts.addParamValue('wfnorms', []);
opts.addParamValue('true_sp', {});
opts.addParamValue('location_slack', 30); % Allowed mismatch in timing for comparison to ground truth
opts.parse(varargin{:});
opts = opts.Results;

% Setup figure
f = opts.f;
if isempty(f)
  f = figure(132973478);  %%@magic number but no biggie
  f.NumberTitle = 'off';
  f.Name = 'Threshold Visualization';
else
  figure(f); clf
end

n = length(spikeamps);
setappdata(f, 'spikeamps', spikeamps);

% Store initial thresh value
if length(initthresh) < length(spikeamps)
    error('Not enough initial thresholds provided.');
end
setappdata(f, 'initthresh', initthresh);
setappdata(f, 'amp_thresholds', initthresh);

% Modify spiketimes by dt
spiketimes = cellfun(@(st) st.*opts.dt, spiketimes,   'UniformOutput', false);
true_sp    = cellfun(@(st) st.*opts.dt, opts.true_sp, 'UniformOutput', false);
slack = opts.location_slack*opts.dt;
setappdata(f, 'spiketimes', spiketimes);
setappdata(f, 'true_sp', true_sp);
setappdata(f, 'location_slack', slack);

% Store initial thresholding
threshspiketimes = cell(size(spiketimes));
for i = 1:n
    threshspiketimes{i} = spiketimes{i}(spikeamps{i} > initthresh(i));
end
setappdata(f, 'threshspiketimes', threshspiketimes);

v = ver();
haveipt = any(strcmp('Image Processing Toolbox', {v.Name}));
cols = hsv(n);
for i = 1:n
    subplot(n+1, n, i); cla;

    % Plot spike amplitude histogram
    [H, X] = hist(spikeamps{i}, opts.ampbins);
    hh = bar(X,H); set(hh,'FaceColor', cols(i,:), 'EdgeColor', cols(i,:));
    title(sprintf('Amplitudes, cell %d', i));
    xl = [0 max([spikeamps{i}(:); 1.5])];
    xlim(xl);

    if (~isempty(opts.wfnorms))
        X = linspace(0,xl(2),opts.ampbins);
        hold on
        plot(X, max(H)*exp(-((X*opts.wfnorms(i)).^2)/2), 'Color', 0.35*[1 1 1]);
        %        plot(X, max(H)*exp(-(((X-1)*opts.wfnorms(i)).^2)/2), 'Color', cols(i,:));

        hold off
    end

    % Plot threshold as vertical lines.
    hold on;
    yl = get(gca, 'YLim');
    if haveipt
        xl = get(gca, 'XLim');
        cnstrfcn = makeConstrainToRectFcn('imline', xl, yl);
        lh = imline(gca, initthresh(i)*[1 1], yl, 'PositionConstraintFcn', cnstrfcn);
        lh.setColor('black');
        lch = get(lh, 'Children');
        set(lch(1:2), 'HitTest', 'off');
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
uih = uicontrol(f, 'Style', 'pushbutton', ...
                'String', 'Use thresholds', ...
                'Position', [pos(1), pos(2)+ht/2, pos(3), ht/2].*[wsz,wsz], ...
                'Callback', @acceptCallback);
uih = uicontrol(f, 'Style', 'pushbutton', ...
                'String', 'Revert to default', ...
                'Position', [pos(1), pos(2), pos(3), ht/2].*[wsz,wsz], ...
                'Callback', @revertCallback);

% if nargout < 1, clear f; end
return

% -----------------
function acceptCallback(hObject, eventdata)
  global dataobj;
  ampthresh = getappdata(gcbf, 'amp_thresholds');
  dataobj.CBPinfo.amp_thresholds = ampthresh;
  return

% -----------------
function revertCallback(hObject, eventdata)
  global dataobj;
  initthresh = getappdata(gcbf, 'initthresh');
  dataobj.CBPinfo.amp_thresholds = initthresh;
  for i=1:length(getappdata(gcbf, 'amp_thresholds'))
      updateThresh(initthresh(i), i, gcbf);
  end
  return

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

% -----------------
function updateThresh(newthresh, i, f)
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
setappdata(f, 'amp_thresholds', amp_thresholds);
return

% -----------------
function plotACorr(spiketimes, i)
n = length(spiketimes);
subplot(n+1, n, sub2ind([n n+1], i, 2));
psthacorr(spiketimes{i})
title(sprintf('Autocorr, cell %d', i));
if (i==1), xlabel('time (sec)'); end
return

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
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/postproc/AmplitudeThresholdGUI.m
