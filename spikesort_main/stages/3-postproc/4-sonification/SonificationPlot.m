function SonificationPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Sonification');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    % local variables to reuse
    dt = CBPdata.whitening.dt;
    fs = round(1/dt);
    nsamples = CBPdata.whitening.nsamples;

    reconstructed = CBPdata.sonification.reconstructed;
    reconstructedclean = CBPdata.sonification.reconstructedclean;
    orig = CBPdata.sonification.orig;
    tab = CreateCalibrationTab('Sonification', 'Sonification');

% -------------------------------------------------------------------------
% Plot left channel
    subplot(2,2,1);

    % NOTE: right now, RegisterScrollAxes only works with multiplots, so
    % I have this as a multiplot with only one lineseries. Kind of strange,
    % but works alright
    plots = {};
    plots{end+1} = [];
    plots{end}.dt = dt;
    plots{end}.y = reconstructed;

    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);
    plot_l = gca;
    ylim_l = getappdata(gca,"globylim");

    multiplotxlabel('Time (sec)');
    multiplottitle(sprintf('(L) Reconstructed signal mixdown'));

% -------------------------------------------------------------------------
% Plot right channel
    subplot(2,2,3);

    plots = {};
    plots{end+1} = [];
    plots{end}.dt = dt;
    plots{end}.y = orig;

    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);
    plot_r = gca;
    ylim_r = getappdata(gca,"globylim");

    multiplotxlabel('Time (sec)');
    multiplottitle('(R) Original signal mixdown');

% -------------------------------------------------------------------------
% Sync channel axes

    % get the max range of both plots
    ylim_max = [min(ylim_l(1), ylim_r(1)) max(ylim_l(2), ylim_r(2))];
    
    % set left plot as current and call multiplotsubfunc
    axes(plot_l);
    multiplotsubfunc(@ylim, ylim_max);
    
    % likewise with right plot
    axes(plot_r);
    multiplotsubfunc(@ylim, ylim_max);

% -------------------------------------------------------------------------
% Plot scatter plot

    subplot(2,2,[2 4]);
    scatter(orig, reconstructedclean, '.');
    title('Original (x) vs Reconstructed (y)');

    % make axes square
    axis tight;
    lim = [0 0];
    xl = xlim;
    yl = ylim;
    lim(1) = min(xl(1), yl(1));
    lim(2) = max(xl(2), yl(2));
    xlim(lim);
    ylim(lim);

    % set up ticks
    yt = yticks;
    xticks(yt);
    grid on;
    axis square;

    % labels
    xlabel('Original Signal');
    ylabel('Reconstructed Signal');
% -------------------------------------------------------------------------
% Add button
    f = GetCalibrationFigure;
    parent = tab;
    global button;
    button = uicontrol(parent, ...
        'Style', 'pushbutton', ...
        'String', sprintf('Play Stereo Clip'), ...
        'FontSize', 18, ...
        'Units', 'normalized', ...
        'Position', [.6 .90 .3 .05], ...
        'Callback', @PlaySonificationSound);
    label = uicontrol(parent, ...
        'Style', 'text', ...
        'String', sprintf('(Headphones Required)'), ...
        'FontSize', 14, ...
        'Units', 'normalized', ...
        'Position', [.6 .85 .3 .05]);

    PlaySonificationSound;
end


% -------------------------------------------------------------------------
% Play
function PlaySonificationSound(varargin)
    global CBPdata params CBPInternals;

    % local variables to reuse
    dt = CBPdata.whitening.dt;
    fs = round(1/dt);
    nsamples = CBPdata.whitening.nsamples;

    reconstructed = CBPdata.sonification.reconstructed;
    reconstructedclean = CBPdata.sonification.reconstructedclean;
    orig = CBPdata.sonification.orig;

    startsamp = round(params.plotting.xpos*(nsamples-1))+1;
    endsamp = round(startsamp + nsamples/2^(params.plotting.zoomlevel-1));

    startsamp = max(startsamp,1);
    endsamp = min(endsamp,nsamples);

    reconstructed = reconstructed(startsamp:endsamp);
    orig = orig(startsamp:endsamp);

    out = [reconstructed orig];
    clear sound;
    sound(out/16,fs);
end