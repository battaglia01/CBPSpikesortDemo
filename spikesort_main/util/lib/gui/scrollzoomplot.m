%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% scrollzoomplot.m - Mike Battaglia
%% Turns the axes specified into a plot with a scrollbar and zoom buttons
%% Call via scrollzoomplot(gca)

function out=scrollzoomplot(cur_ax)
    % now decrease height by 10% and add scrollbar there
    old_plot_pos = get(cur_ax,'Position');
    new_plot_pos = [old_plot_pos(1), old_plot_pos(2)+0.1*old_plot_pos(4), ...
                    old_plot_pos(3), old_plot_pos(4)*0.9];
    new_bar_pos  = [old_plot_pos(1)+0.1*old_plot_pos(3), old_plot_pos(2)-0.2*old_plot_pos(4), ...
                    old_plot_pos(3)*0.8                 , old_plot_pos(4)*0.1];
    set(cur_ax,'Position',new_plot_pos);
    
    % create scrollbar and set initial position
    hscrollbar=uicontrol(get(cur_ax,'Parent'),...
                        'style','slider',...
                        'units','normalized',...
                        'position',new_bar_pos);
    rescaleScrollbar(cur_ax,hscrollbar);
    
    % add callbacks for scrolling
    set(hscrollbar,     'callback', @(varargin)processScrollbar(cur_ax,hscrollbar));
    addlistener(cur_ax, 'XLim', 'PostSet', @(varargin)rescaleScrollbar(cur_ax,hscrollbar));

    % now create zoom buttons
    zoomout_pos = [old_plot_pos(1),                      old_plot_pos(2)-0.2*old_plot_pos(4), ...
                   old_plot_pos(3)*0.05,                 old_plot_pos(4)*0.1];
    zoomin_pos  = [old_plot_pos(1)+old_plot_pos(3)*0.05, old_plot_pos(2)-0.2*old_plot_pos(4), ...
                   old_plot_pos(3)*0.05,                 old_plot_pos(4)*0.1];
    sync_pos  =   [old_plot_pos(1)+old_plot_pos(3)*0.90, old_plot_pos(2)-0.2*old_plot_pos(4), ...
                   old_plot_pos(3)*0.1,                  old_plot_pos(4)*0.1];
    zoomout = uicontrol(get(cur_ax,'Parent'),...
                            'Style','pushbutton',...
                            'Units','normalized',...
                            'String','-',...
                            'Position', zoomout_pos,...
                            'Callback', @(varargin)processZoom(cur_ax,2));
    zoomin  = uicontrol(get(cur_ax,'Parent'),...
                            'Style','pushbutton',...
                            'Units','normalized',...
                            'String','+',...
                            'Position', zoomin_pos,...
                            'Callback', @(varargin)processZoom(cur_ax,1/2));
    syncall  = uicontrol(get(cur_ax,'Parent'),...
                            'Style','pushbutton',...
                            'Units','normalized',...
                            'String','Sync',...
                            'Position', sync_pos);
    set(syncall, 'Callback', @(varargin)processSync(cur_ax, syncall));
end


function dataxlim = getDataLimits(cur_ax)
    dataxlim = [Inf -Inf];
    p = get(cur_ax,'Children');
    for n=1:length(p)
        if isequal(get(p(n),'Type'), 'line')
            dataxlim(1) = min(dataxlim(1), min(p(n).XData));
            dataxlim(2) = max(dataxlim(2), max(p(n).XData));
        end
    end
end

function processSync(cur_ax, button)
    set(button,'String','...');
    plotxlim = xlim(cur_ax);
    ChangeScroll(plotxlim(1), plotxlim(2));
    set(button,'String','Sync');
end

function processZoom(cur_ax,scl)
    % get existing limits
    plotxlim = xlim(cur_ax);
    midxlim = mean(plotxlim);
    rangexlim = range(plotxlim);
    
    %get new limits
    rangexlim = rangexlim * scl;
    plotxlim(1) = midxlim - rangexlim/2;
    plotxlim(2) = midxlim + rangexlim/2;
    
    %check for underflow and validity set
    if plotxlim(1) < plotxlim(2) && isvalid(cur_ax)
        xlim(cur_ax,plotxlim);
    end
end

function processScrollbar(cur_ax,scroll)
    % get limits
    plotxlim = xlim(cur_ax);
    dataxlim = getDataLimits(cur_ax);
    
    % get bar value from scrollbar
    bar_value = get(scroll,'Value');
    
    % compute x position by inverting the rescaleScrollbar function
    plotrange = range(plotxlim);
    plotxlim(1) = bar_value * (range(dataxlim) - range(plotxlim)) + dataxlim(1);
    plotxlim(2) = plotxlim(1) + plotrange;
    
    %check we're still valid and set
    if isvalid(cur_ax)
        xlim(cur_ax,plotxlim);
    end
end

function rescaleScrollbar(cur_ax,scroll)
    % get limits
    plotxlim = xlim(cur_ax);
    dataxlim = getDataLimits(cur_ax);
    
    %if left edge is off the left side, keep same range but just slide
    if plotxlim(1) < dataxlim(1)
        plotxlim(2) = dataxlim(1) + range(plotxlim);
        plotxlim(1) = dataxlim(1);
    end
    
    %if right edge is off the right side, keep same range but just slide
    if plotxlim(2) > dataxlim(2)
        plotxlim(1) = dataxlim(2) - range(plotxlim);
        plotxlim(2) = dataxlim(2);
    end
    
    %the only way the above can fail is if the range is too big, so correct
    %range if too wide. do this last to correct floating point errors
    if range(plotxlim) > range(dataxlim)
        plotxlim = dataxlim;
    end
    xlim(cur_ax,plotxlim);
    
    %compute bar_step. MATLAB requires us to convert from 1/3 -> 1/2,
    %1/2 -> 1/1, etc for some stupid reason. The below does that
    bar_step = range(plotxlim)/range(dataxlim);
    bar_step = 1/(1/bar_step-1);
    if bar_step < 0
        bar_step = Inf;
    end
    
    %now get bar value
    bar_value = (plotxlim(1)-dataxlim(1))/(range(dataxlim) - range(plotxlim));
    if isnan(bar_value)
        bar_value = 0;
    end
    
    %make sure we're still valid and set
    if isvalid(scroll)
        set(scroll, ...
            'SliderStep',[min(bar_step/2,1),bar_step], ...
            'Value', bar_value);
    end
end