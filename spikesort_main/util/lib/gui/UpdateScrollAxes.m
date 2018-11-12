function UpdateScrollAxes(ax)
global dataobj params cbpglobals;
    if ~isfield(cbpglobals,'scrollaxes')
        cbpglobals.scrollaxes=[gobjects(0)];
    else
        %prune old axes
        cbpglobals.scrollaxes = cbpglobals.scrollaxes(isvalid(cbpglobals.scrollaxes));

        %check we're not empty
        if isempty(cbpglobals.scrollaxes)
            return;
        end

        %set x axis limits for first of linked axes (hence all of them)

        %set all x axes to the plot times, set y axis to min and max for
        %each plot
        for n=1:length(cbpglobals.scrollaxes)
            xlim(cbpglobals.scrollaxes(n),params.plotting.data_plot_times);
            drawnow limitrate nocallbacks;
            pause(.01);
            
            %get the min/max for the series
            ymin = Inf;
            ymax = -Inf;
            lines = get(cbpglobals.scrollaxes(n),'Children');
            for l = 1:length(lines)
                line  = lines(l);
                if isequal(get(line,'Type'), 'line')
                    ymin = min(ymin, min(line.YData));
                    ymax = max(ymax, max(line.YData));
                end
            end
            ylim(cbpglobals.scrollaxes(n), [ymin ymax]);
        end
        drawnow;
        pause(.01);
    end
end
