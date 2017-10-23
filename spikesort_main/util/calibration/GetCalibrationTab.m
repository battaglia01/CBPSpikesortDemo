function t = GetCalibrationTab(name)
    tg = findobj('Tag','calibration_tg');
    t = findobj('Tag',['calibration_t_' name]);
    
    if(~isempty(tg) && ~isempty(t))
        GetCalibrationFigure;
        tg.SelectedTab = t;
    end
end