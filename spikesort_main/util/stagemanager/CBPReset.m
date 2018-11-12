function CBPReset
	global dataobj params cbpglobals;
    
    % Calibration figure
    if ishghandle(params.plotting.calibration_figure)
        close(params.plotting.calibration_figure);
    end
    
    % Params figure
    if ishghandle(params.plotting.params_figure)
        close(params.plotting.params_figure);
    end
    
    clear global dataobj params cbpglobals;
end
