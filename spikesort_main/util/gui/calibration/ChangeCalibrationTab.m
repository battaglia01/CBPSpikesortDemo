% Changes the calibration figure to the specified tab, if it exists.

function t = ChangeCalibrationTab(name)
    tg = findobj('Tag','calibration_tg');
    t = findobj('Tag',['calibration_t_' name]);
    
    if(~isempty(tg) && ~isempty(t))
        GetCalibrationFigure;
        tg.SelectedTab = t;
    end
end