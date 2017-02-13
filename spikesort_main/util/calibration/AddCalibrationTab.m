function [t,a] = AddCalibrationTab(name)
    %First load up the figure and check the tab doesn't already exist
    GetCalibrationFigure;
    ttest = findobj('Tag',['calibration_t_' name]);
    if(~isempty(ttest))
        [t, a] = GetCalibrationTab(name);
        return;
    end
    
    %Now create the tab and switch to it
    tg = findobj('Tag','calibration_tg');
    t = uitab(tg,'Title',name,'Tag',['calibration_t_' name]);
    a = axes('Parent',t);
    tg.SelectedTab = t;
end