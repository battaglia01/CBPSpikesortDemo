function h = GetCalibrationFigure
global params dataobj;
    if ~ishghandle(params.plotting.calibration_figure)
        %If it doesn't already exist, create it
        h = figure(params.plotting.calibration_figure);
        h.NumberTitle = 'off';
        
        %may not have filename yet
        h.Name = 'Calibration'
        
        %Set up basic initial features
        set(gcf, 'ToolBar', 'none');
        scrsz =  get(0,'ScreenSize'); 
        set(gcf, 'OuterPosition', [0.05*scrsz(3) 0.10*scrsz(4) .9*scrsz(3) .85*scrsz(4)]);

        %Set up tab group
        tg = uitabgroup(h, 'TabLocation', 'left', 'Tag', 'calibration_tg');
    else
        h = figure(params.plotting.calibration_figure);
    end
    
    %reset titlebar
    if isfield(dataobj,'filename')
        filenameindex = max(strfind(dataobj.filename,'/'));
        if isempty(filenameindex)
            filenameindex = 0;
        end
        shortname = dataobj.filename(filenameindex+1:end);
        set(h,'Name', [shortname ' - Calibration']);
    end
end