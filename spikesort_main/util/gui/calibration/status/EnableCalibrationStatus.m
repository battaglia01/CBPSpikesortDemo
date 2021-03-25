% Re-enable status bar.
% Usage: EnableCalibrationStatus

function EnableCalibrationStatus
    global CBPInternals;
    SetCalibrationStatusStage(CBPInternals.curr_selected_tab_stage);
end
