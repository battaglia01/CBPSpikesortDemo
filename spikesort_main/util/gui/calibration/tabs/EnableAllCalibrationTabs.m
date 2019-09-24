% Enables all the calibration tabs.

function EnableAllCalibrationTabs
    global CBPInternals;
    if isfield(CBPInternals, 'tabbedpaneref')
        CBPInternals.tabbedpaneref.setEnabled(1);
    else
        f = GetCalibrationFigure;
        jtg = findjobj(f, 'class', 'JTabbedPane');
        jtg.setEnabled(1);
        CBPInternals.tabbedpaneref = jtg;
    end
end
