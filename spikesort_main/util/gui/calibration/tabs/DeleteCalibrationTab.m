function DeleteCalibrationTab(name)
    %First load up the figure and check the tab doesn't already exist.
    f = GetCalibrationFigure;
    tg = LookupTag('calibration_tg');
    tname = formattagname(name);
    ttest = LookupTag(tname);

    %If ttest is empty, tab doesn't exist yet, so don't worry about this.
    %If it does, disable it.
    if(~isempty(ttest))
        t = ChangeCalibrationTab(name);
        UnregisterTag(t);
        delete(t.Children);
        delete(t);
    end
end
