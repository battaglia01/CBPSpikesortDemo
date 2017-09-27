<<<<<<< HEAD
function t = AddCalibrationTab(name)
%%@Get rid of the axes, it's no good - should be looking at t.Children

    %First load up the figure and check the tab doesn't already exist.
    GetCalibrationFigure;
    tg = findobj('Tag','calibration_tg');
    ttest = findobj('Tag',['calibration_t_' name]);
    t = [];
    
    %If ttest is empty, tab doesn't exist yet, so create it.
    %If it does, delete all of its children and clear.
    if(isempty(ttest))
        t = uitab(tg,'Title',name,'Tag',['calibration_t_' name]);
    else
        t = GetCalibrationTab(name);
        delete(t.Children);
    end
    
    %Now change the selected tab, and give us a pair of axes to work with.
    tg.SelectedTab = t;
    a = axes('Parent',t);
=======
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
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
end