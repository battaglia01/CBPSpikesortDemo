function UpdateScrollAxes
global CBPdata params CBPInternals;
    if ~isfield(CBPInternals,'scrollaxes')
        CBPInternals.scrollaxes=[gobjects(0)];
    else
        % prune old axes
        CBPInternals.scrollaxes = CBPInternals.scrollaxes(isvalid(CBPInternals.scrollaxes));

        % prune invalid axes
        todelete = [];
        for n=1:length(CBPInternals.scrollaxes)
            if ~isequal(getappdata(CBPInternals.scrollaxes(n),'PyramidZoomPlot'),'true')
                todelete(end+1) = n;
            end
        end
        CBPInternals.scrollaxes(todelete) = [];

        % check we're not empty
        if isempty(CBPInternals.scrollaxes)
            return;
        end

        % set x axis limits for first of linked axes (hence all of them)

        % set all x axes to the plot times, set y axis to min and max for
        % each plot
        for n=1:length(CBPInternals.scrollaxes)
            rescalefun = getappdata(CBPInternals.scrollaxes(n),'rescale');
            rescalefun(params.plotting.zoomlevel, params.plotting.xpos);
            % drawnow limitrate nocallbacks;
            % pause(.01);
        end
        drawnow;
        pause(.01);
    end
end
