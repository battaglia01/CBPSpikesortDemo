% Disables all the calibration tabs.

function DisableAllCalibrationTabs
    f = GetCalibrationFigure;
    jtg = findjobj(f, 'class', 'JTabbedPane');
    jtg.setEnabled(0);
end