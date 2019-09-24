% Helper function that sets whether the Calibration window is currently
% "loading" or not. Disables status bar and info panel.

function SetCalibrationLoading(state)
    if state == true
        DisableAllCalibrationTabs;
        DisableCalibrationStatus;
        DisableCalibrationInfoPanel;
    else
        EnableAllCalibrationTabs;
        EnableCalibrationStatus;
        EnableCalibrationInfoPanel;
    end
    
    pause(0.01);
    drawnow;
end