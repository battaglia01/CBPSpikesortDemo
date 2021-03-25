% Changes the calibration figure to the specified tab, if it exists.
% DOES NOT update Calibration status or internals.
function t = ChangeCalibrationTab(name)
    global CBPInternals;
    % lookup tab
    f = GetCalibrationFigure;
    tname = formattagname(name);
    tg = LookupTag('calibration_tg');
    t = LookupTag(tname);

    % if it exists, change, and change internals
    if(~isempty(tg) && ~isempty(t))
        GetCalibrationFigure;
        tg.SelectedTab = t;
        currstage = getappdata(t,"stageobj");
    end
end
