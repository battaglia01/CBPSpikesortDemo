% Gets a reference to the specified tab, if it exists.
% DOES NOT change the tab, update Calibration status or internals.
% It does create the CalibrationFigure if it doesn't already exist.
% This is empty if it doesn't already exist.
function t = GetCalibrationTab(name)
    global CBPInternals;
    % lookup tab
    f = GetCalibrationFigure;
    tname = formattagname(name);
    tg = LookupTag('calibration_tg');
    t = LookupTag(tname);

    % if it exists, just return t
end
