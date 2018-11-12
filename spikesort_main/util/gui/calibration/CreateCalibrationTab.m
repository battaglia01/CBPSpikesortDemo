function t = CreateCalibrationTab(name, stagename)
%%@Get rid of the axes, it's no good - should be looking at t.Children

    %First load up the figure and check the tab doesn't already exist.
    GetCalibrationFigure;
    tg = findobj('Tag','calibration_tg');
    ttest = findobj('Tag',['calibration_t_' name]);
    t = [];
    
    %If ttest is empty, tab doesn't exist yet, so create it.
    %If it does, delete all of its children and clear.
    if(isempty(ttest))
        t = uitab(tg,'Title',name,'Tag',['calibration_t_' name], 'UserData', GetStageFromName(stagename));
    else
        t = ChangeCalibrationTab(name);
        delete(t.Children);
    end
    
    %Now change the selected tab, and give us a pair of axes to work with.
    tg.SelectedTab = t;
    a = axes('Parent',t);
end