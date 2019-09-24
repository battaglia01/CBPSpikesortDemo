%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PyramidZoomPlot.m - Mike Battaglia
% Input is a cell array of objects containing plot arguments
%
% Assumes each line object has properties "dt", "y", and "args" (cell array)
% We don't use "x" for lineseries because we assume everything is evenly
% spaced and starts at 0
%
%%@ NOTE - currently assumes all plots are same length and sample rate
%%@   and furthermore, when synchronizing multiple plots, that they're
%%@   the same length and sample rate

function under_panel = PyramidZoomMultiPlot(plots)
    global CBPInternals;    % for LookAndFeel
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Preprocess input
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % some preliminary stuff we will need for colors
    % NOTE - axes are first created here
    defcolors = get(gca,'colororder');
    numcolorless = 0;

    % set aside the first "dt" and length of y to compare
    compdt = -Inf;
    complen = -Inf;

    % keep track of global min and max for each plot entry
    globmin = Inf;
    globmax = -Inf;

    for n=1:length(plots)
        % Create type if it doesn't exist
        if ~isfield(plots{n}, 'type')
            plots{n}.type = 'plot';
        end

        % Create blank args if doesn't exist
        if ~isfield(plots{n}, 'args')
            plots{n}.args = {};
        end

        % if we don't have a plot, continue
        if ~isequal(plots{n}.type, 'plot')
            continue;
        end

        % If dt isn't specified, assume it's "1" by default
        if ~isfield(plots{n},'dt')
            plots{n}.dt = 1;
        end

        if ~isfield(plots{n},'args')
            plots{n}.args = {};
        end

        % Add the pyramid plot y-axes to min-max pyramid
        plots{n}.pyr = MinMaxPyramid(plots{n}.y);

        % Update global max and min
        globmax = max(globmax, plots{n}.pyr.maxpyr{1});
        globmin = min(globmin, plots{n}.pyr.minpyr{1});

        % Set the default color properly - if not specified, keep track of
        % the number of "colorless" entries, and then cycle through
        % successive default colors
        if ~any(strcmpi(plots{n}.args, 'color'))
            numcolorless = mod(numcolorless, size(defcolors,1))+1;
            plots{n}.args(end+1:end+2) = {'color', defcolors(numcolorless,:)};
        end

        if compdt == -Inf || complen == -Inf
            compdt = plots{n}.dt;
            complen = length(plots{n}.y);
        else
            assert(compdt == plots{n}.dt && complen == length(plots{n}.y), ...
              'ERROR: All plots must have the same dt and length.');
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create axes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % First, Set look and feel
    % Taken from http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    newLnF = 'javax.swing.plaf.metal.MetalLookAndFeel';
    javax.swing.UIManager.setLookAndFeel(newLnF);

    % Create axes and set to data plot times
    %%@ this is currently a dummy axes, and becomes the "under_panel" from multiplot.
    %%@ should maybe change
    under_panel = gca;
    set(under_panel, 'Visible', 'off');  %%@ also done in multiplot, but couldn't hurt

    % Store each plot in axes
    setappdata(under_panel,'rawplots',plots); %raw plots before pyramidization
    setappdata(under_panel,'globylim',[globmin globmax]);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set up scrollbars
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % now decrease height by 10% and add scrollbar there
    %%@ Maybe needs some more adjusting
    old_plot_pos = get(under_panel,'Position');
    new_plot_pos = [old_plot_pos(1), old_plot_pos(2)+0.1*old_plot_pos(4), ...
                    old_plot_pos(3), old_plot_pos(4)*0.9];
    new_bar_pos  = [old_plot_pos(1)+0.1 * old_plot_pos(3), old_plot_pos(2) - old_plot_pos(4)^(0.2)*0.08, ...
                    old_plot_pos(3)*0.8                  , old_plot_pos(4)^(0.2)*0.04];
    set(under_panel,'Position',new_plot_pos);

    % create scrollbar and set initial position
    hscrollbar = uicontrol(get(under_panel,'Parent'),...
                           'style','slider',...
                           'units','normalized',...
                           'position',new_bar_pos);
    set(hscrollbar, 'callback', @(varargin)scrollHandler(under_panel,hscrollbar));

    % now create zoom buttons
    zoomout_pos = [old_plot_pos(1),                      new_bar_pos(2), ...
                   old_plot_pos(3)*0.05,                 new_bar_pos(4)];
    zoomin_pos  = [old_plot_pos(1)+old_plot_pos(3)*0.05, new_bar_pos(2), ...
                   old_plot_pos(3)*0.05,                 new_bar_pos(4)];
    sync_pos    = [old_plot_pos(1)+old_plot_pos(3)*0.90, new_bar_pos(2), ...
                   old_plot_pos(3)*0.1,                  new_bar_pos(4)];

    zoomout = uicontrol(get(under_panel,'Parent'),...
                        'Style','pushbutton',...
                        'Units','normalized',...
                        'FontUnits','normalized',...
                        'String','-',...
                        'Position', zoomout_pos,...
                        'Callback', @(varargin)zoomHandler(under_panel,-1));
    zoomin  = uicontrol(get(under_panel,'Parent'),...
                        'Style','pushbutton',...
                        'Units','normalized',...
                        'FontUnits','normalized',...
                        'String','+',...
                        'Position', zoomin_pos,...
                        'Callback', @(varargin)zoomHandler(under_panel,1));
    syncall = uicontrol(get(under_panel,'Parent'),...
                        'Style','pushbutton',...
                        'Units','normalized',...
                        'FontUnits','normalized',...
                        'FontSize',0.6,...
                        'String','Sync',...
                        'Position', sync_pos);
    set(syncall, 'Callback', @(varargin)syncHandler(under_panel, syncall));


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initialize axes
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set x axis to do initial zoom.
    % NOTE: initial plot is done here, in `rescalePlot`, which does the pyramid
    % stuff
    initzoom = 1;
    rescalePlot(under_panel, initzoom, 0);
    rescaleScrollbar(hscrollbar, initzoom, 0);

    setappdata(under_panel, 'zoomlevel', initzoom);
    setappdata(under_panel, 'xpos', 0);
    setappdata(under_panel, 'rescale', @(z,x) rescaleAll(under_panel, hscrollbar, z, x));
    setappdata(under_panel, 'PyramidZoomPlot', 'true');   %sometimes MATLAB adds the wrong axes if stage is interrupted

    % Ensure that the controls are fully-rendered before restoring the L&F
    drawnow;
    pause(0.05);

    %Restore original look and feel
    javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);
    axes(under_panel);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Auxiliary functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This changes the xlim and finds the right part of the pyramid.
% The "zoomlevel" is how many levels in we're zoomed
% (actual zoom factor is 2^zoomlevel).
% The "xpos" is what percentage of the way we are to the end
%%@ this is where things are first plotted.
function rescalePlot(under_panel, zoomlevel, xpos)
    % first, get plots
    plots = getappdata(under_panel, 'rawplots');

    % get reference dt, len, and maxpyr len from first "plot" type
    for n=1:length(plots)
        if isfield(plots{n}, 'type') && isequal(plots{n}.type, 'plot')
            dt = plots{n}.dt;
            len = length(plots{n}.y);
            pyrlen = length(plots{n}.pyr.maxpyr);
            break;
        end
    end

    % then, use the current resolution of the screen to determine
    % what pyramid level counts as "zoomlevel=1".
    % get the next largest power of 2, then go one power of two higher
    % to plot - some padding is good for aliasing
    res = max(max(ScreenInfo));
    zoomoffset = ceil(log2(res));

    % set time indices accordingly, using the first plot as reference
    maxtime = (len-1)*dt;
    pyrind = zoomlevel + zoomoffset;

    % treat the situation differently if we're past the end of the pyramid
    if pyrind <= pyrlen
        time_start = maxtime * xpos;
        time_end = time_start + maxtime/2^(zoomlevel-1);
            numpoints = 2^(zoomoffset);

        ind_start = round(1+xpos.*numpoints);
        inds = ind_start:(ind_start+2^zoomoffset-1);
        x = linspace(time_start,time_end,numpoints);
    else
        time_start = maxtime * xpos;
        time_end = time_start + maxtime/2^(zoomlevel-1);
        inds = (round(1+xpos.*len):round((xpos + 1/2^(zoomlevel-1)).*len));
        x = linspace(time_start,time_end,length(inds));
    end

    % collect multiplots, then plot
    multiplots = plots;
    for n=1:length(multiplots)
        if ~isequal(multiplots{n}.type, 'plot')
            continue;
        end
        if pyrind <= pyrlen                         % if we're in pyramid range
            xplot = upsample(x,2) + upsample(x,2,1);
            yplot = upsample(plots{n}.pyr.maxpyr{pyrind}(inds),2) + ...
                    upsample(plots{n}.pyr.minpyr{pyrind}(inds),2,1);
            multiplots{n}.x = xplot;
            multiplots{n}.y = yplot;
        else                                        % just plot directly
            multiplots{n}.x = x;
            multiplots{n}.y = plots{n}.y(inds);
        end
    end

    % check to see if we've already multiplotted
    axes(under_panel);
    if isempty(getappdata(under_panel, 'panel'))
        panel = multiplot(multiplots); %%@ change to multiplot
        ax = getappdata(panel, 'mp_axes');
        setappdata(under_panel, 'panel', panel); %%@! may be redundant??
    else
        panel = multiplot(getappdata(under_panel, 'panel'), multiplots); %%@ change to multiplot
        ax = getappdata(panel, 'mp_axes');
        setappdata(under_panel, 'panel', panel); %%@! may be redundant??
    end

    % now change ticks. have to do this due to MATLAB tick bug!
    xran = time_end - time_start;
    xres = 10^floor(log10(xran));

    if xran/xres < 2
        xres = xres / 10;
    elseif xran/xres < 3
        xres = xres / 5;
    elseif xran/xres < 5
        xres = xres / 2;
    end

    multiplotsubfunc(@xticks, 0:xres:maxtime);

    % lastly, set xlim and ylim
    globylim = getappdata(under_panel, 'globylim');
    multiplotsubfunc(@xlim, [time_start time_end]);

    %%@ MIKE NOTE - this was commented for some reason. comment below
    %%% doing the y-axis by default caused problems - better to set manually
    %%% left for reference
    multiplotsubfunc(@ylim, globylim);

    % refocus old axes
    axes(under_panel);
end

function syncHandler(under_panel, button)
    set(button,'String','...');
    zoomlevel = getappdata(under_panel,'zoomlevel');
    xpos = getappdata(under_panel,'xpos');
    RescaleAxes(zoomlevel, xpos);
    set(button,'String','Sync');
end

% Processes the zoom +/- buttons.
function zoomHandler(under_panel,zoomincr)
    oldzoom = getappdata(under_panel,'zoomlevel');
    newzoom = oldzoom + zoomincr;

    % out of bounds - having the zoom more than 19 would screw up the
    % scrollbar
    if newzoom < 1 || newzoom > 19
        return;
    end

    % center the scrollbar on the old zoom
    oldxpos = getappdata(under_panel, 'xpos');
    if zoomincr == -1
        newxpos = oldxpos - 1/2^(newzoom+1);
    else
        newxpos = oldxpos + 1/2^(newzoom);
    end

    % make sure we didn't scroll too far either way
    newxpos = max(newxpos,0);
    newxpos = min(newxpos,1-1/2^(newzoom-1));

    rescalefun = getappdata(under_panel, 'rescale');
    rescalefun(newzoom, newxpos);
end

% Processes the scrollbar event handler.
function scrollHandler(under_panel,scroll)
    curzoom = getappdata(under_panel,'zoomlevel');
    rawxpos = get(scroll,'Value');
    newxpos = rawxpos * (1-1/(2^(curzoom-1)));

    rescalefun = getappdata(under_panel, 'rescale');
    rescalefun(curzoom, newxpos);
end

% Rescales the scrollbar. Called after zooming or clicking an arrow button.
function rescaleScrollbar(scroll,zoomlevel,xpos)
    % compute bar_step. MATLAB requires us to convert from 1/3 -> 1/2,
    % 1/2 -> 1/1, etc for some stupid reason. The below does that

    if zoomlevel <= 1
        %we've zoomed out too much
        small_bar_step = 1;
        large_bar_step = Inf;
        bar_value = 0;
    else
        % MATLAB says bar_step can't be below 1e-6, so since we divide by
        % 2, shouldn't be less than 2e-6. make it 2.1e-6 for safety
        large_bar_step = max(2.1e-6,1/(2^(zoomlevel-1)-1));
        small_bar_step = large_bar_step/2;
        bar_value = xpos/(1-1/(2^(zoomlevel-1)));
    end

    set(scroll, ...
        'SliderStep',[small_bar_step large_bar_step], ...
        'Value', bar_value);
end

% quick aux function that calls both rescale functions
function rescaleAll(under_panel, hscrollbar, zoomlevel, xpos)
% set app data and plot
    setappdata(under_panel, 'zoomlevel', zoomlevel);
    setappdata(under_panel, 'xpos', xpos);

    rescalePlot(under_panel, zoomlevel, xpos);
    rescaleScrollbar(hscrollbar, zoomlevel, xpos);
end
