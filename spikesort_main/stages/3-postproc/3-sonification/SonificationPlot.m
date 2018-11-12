function SonificationPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Sonification');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    % local variables to reuse
    dt = dataobj.whitening.dt;
    fs = round(1/dt);
    nsamples = dataobj.whitening.nsamples;

    reconstructed = dataobj.sonification.reconstructed;
    reconstructedclean = dataobj.sonification.reconstructedclean;
    orig = dataobj.sonification.orig;
    CreateCalibrationTab('Sonification', 'Sonification');

% -------------------------------------------------------------------------
% Plot left channel

    subplot(2,2,1);
    plot((0:nsamples-1)*dt, reconstructed);
    plot_l = gca;
    ylim_l = ylim;
    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    xlabel('Time (sec)');
    title('(L) Reconstructed signal mixdown, with Gaussian noise added');

% -------------------------------------------------------------------------
% Plot right channel

    subplot(2,2,3);
    plot((0:nsamples-1)*dt, orig);
    plot_r = gca;
    ylim_r = ylim;
    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    xlabel('Time (sec)');
    title('(R) Original signal mixdown');

% -------------------------------------------------------------------------
% Sync channel axes

    ylim_max = [min(ylim_l(1), ylim_r(1)) max(ylim_l(2), ylim_r(2))];
    ylim(plot_l, ylim_max);
    ylim(plot_r, ylim_max);

% -------------------------------------------------------------------------
% Plot scatter plot

    subplot(2,2,[2 4]);
    scatter(reconstructedclean, orig, '.');
    title('Reconstructed (x) vs original (y)');

    %make axes square
    axis tight;
    lim = [0 0];
    xl = xlim;
    yl = ylim;
    lim(1) = min(xl(1), yl(1));
    lim(2) = max(xl(2), yl(2));
    xlim(lim);
    ylim(lim);

    %set up ticks
    yt = yticks;
    xticks(yt);
    grid on;
    axis square;

% -------------------------------------------------------------------------
% Add button

    parent = findobj('Tag','calibration_t_Sonification');
    global button;
    button = uicontrol(parent, ...
        'Style', 'pushbutton', ...
        'String', sprintf('Play Stereo Clip'), ...
        'FontSize', 18, ...
        'Units', 'normalized', ...
        'Position', [.6 .85 .3 .1], ...
        'Callback', @playSonificationSound);
    label = uicontrol(parent, ...
        'Style', 'text', ...
        'String', sprintf('(Headphones Required)'), ...
        'FontSize', 14, ...
        'Units', 'normalized', ...
        'Position', [.6 .80 .3 .05]);

    playSonificationSound;
end


% -------------------------------------------------------------------------
% Play filekills
function playSonificationSound(varargin)
    global params dataobj;

    % local variables to reuse
    dt = dataobj.whitening.dt;
    fs = round(1/dt);
    nsamples = dataobj.whitening.nsamples;

    reconstructed = dataobj.sonification.reconstructed;
    reconstructedclean = dataobj.sonification.reconstructedclean;
    orig = dataobj.sonification.orig;

    %truncate to correct size
    startsamp = round(params.plotting.data_plot_times(1)/dt)+1;
    endsamp = round(params.plotting.data_plot_times(2)/dt)+1;

    startsamp = max(startsamp,1);
    endsamp = min(endsamp,nsamples);

    reconstructed = reconstructed(startsamp:endsamp);
    orig = orig(startsamp:endsamp);

    out = [reconstructed orig];
    clear sound;
    sound(out/16,fs);
end