% Disables all the calibration tabs.

function DisableAllCalibrationTabs
    global CBPInternals;
    if isfield(CBPInternals, 'tabbedpaneref')
        CBPInternals.tabbedpaneref.setEnabled(0);
    else
        f = GetCalibrationFigure;
        jtg = findjobj(f, 'class', 'JTabbedPane');
        jtg.setEnabled(0);
        CBPInternals.tabbedpaneref = jtg;
    end
end
