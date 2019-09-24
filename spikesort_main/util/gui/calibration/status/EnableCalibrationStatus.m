% Re-enable status bar.
% Usage: EnableCalibrationStatus

function EnableCalibrationStatus
    global CBPInternals;
    SetCalibrationStatusStage(CBPInternals.currselectedtabstage);
end
