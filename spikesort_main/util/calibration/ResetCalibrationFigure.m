function h = GetCalibrationFigure
global params dataobj;
    if ~ishghandle(params.plotting.calibration_figure)
        %If it doesn't already exist, create it
        h = figure(params.plotting.calibration_figure);
        h.NumberTitle = 'off';
        h.Name = 'Calibration Plot';
        
        %Set up basic initial features
        set(gcf, 'ToolBar', 'none');
        scrsz =  get(0,'ScreenSize'); 
        set(gcf, 'OuterPosition', [.1*scrsz(3) .1*scrsz(4) .8*scrsz(3) .8*scrsz(4)]);

        %Set up tab group
        tg = uitabgroup(h, 'TabLocation', 'left', 'Tag', 'calibration_tg');
    else
        h = figure(params.plotting.calibration_figure);
    end
end