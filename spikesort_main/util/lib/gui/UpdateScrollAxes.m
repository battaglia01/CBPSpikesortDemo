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
        
        %link axes together
        %linkaxes(cbpglobals.scrollaxes,'x');

        %set x axis limits for first of linked axes (hence all of them)

        %set all y axes to auto height
        for n=1:length(cbpglobals.scrollaxes)
            xlim(cbpglobals.scrollaxes(n),params.plotting.data_plot_times);
            drawnow limitrate nocallbacks;
            pause(.01);
            %ylim(cbpglobals.scrollaxes(n),'auto');
        end
        drawnow;
        pause(.01);
    end
end
