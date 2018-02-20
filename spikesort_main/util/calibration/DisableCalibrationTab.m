function DisableCalibrationTab(name)
    %First load up the figure and check the tab doesn't already exist.
    GetCalibrationFigure;
    tg = findobj('Tag','calibration_tg');
    ttest = findobj('Tag',['calibration_t_' name]);
    
    %If ttest is empty, tab doesn't exist yet, so don't worry about this.
    %If it does, disable it.
    if(~isempty(ttest))
        t = GetCalibrationTab(name);
        delete(t.Children);
        delete(t);
    end
end