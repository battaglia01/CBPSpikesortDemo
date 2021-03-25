function UpdateScrollAxes
global CBPdata params CBPInternals;
    if ~isfield(CBPInternals,'pyramid_scroll_axes')
        CBPInternals.pyramid_scroll_axes=[gobjects(0)];
    else
        % prune old axes
        CBPInternals.pyramid_scroll_axes = CBPInternals.pyramid_scroll_axes(isvalid(CBPInternals.pyramid_scroll_axes));

        % prune invalid axes
        todelete = [];
        for n=1:length(CBPInternals.pyramid_scroll_axes)
            if ~isequal(getappdata(CBPInternals.pyramid_scroll_axes(n),'PyramidZoomPlot'),'true')
                todelete(end+1) = n;
            end
        end
        CBPInternals.pyramid_scroll_axes(todelete) = [];

        % check we're not empty
        if isempty(CBPInternals.pyramid_scroll_axes)
            return;
        end

        % set x axis limits for first of linked axes (hence all of them)

        % set all x axes to the plot times, set y axis to min and max for
        % each plot
        for n=1:length(CBPInternals.pyramid_scroll_axes)
            rescalefun = getappdata(CBPInternals.pyramid_scroll_axes(n),'rescale');
            rescalefun(params.plotting.zoomlevel, params.plotting.xpos);
            % drawnow limitrate nocallbacks;
            % pause(.01);
        end
        drawnow;
        pause(.01);
    end
end
