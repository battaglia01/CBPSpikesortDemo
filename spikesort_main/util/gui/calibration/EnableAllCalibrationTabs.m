% Enables all the calibration tabs.

function EnableAllCalibrationTabs
    f = GetCalibrationFigure;
    jtg = findjobj(f, 'class', 'JTabbedPane');
    jtg.setEnabled(1);
end