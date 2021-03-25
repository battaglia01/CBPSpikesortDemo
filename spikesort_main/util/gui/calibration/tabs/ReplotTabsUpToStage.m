% Useful helper function - given a stage name, replots all previous stages up to
% and including the stage. This also re-enables the tabs and sets the
% status stage indicator accordingly.
function ind = ReplotTabsUpToStage(name)
    global CBPInternals params;
    if ~params.plotting.calibration_mode
        return;
    end

    stageobj = GetStageFromName(name);
    for n = 1:stageobj.stagenum
        CBPInternals.stages{n}.plotfun();
    end
    
    %
    EnableAllCalibrationTabs;
    SetCalibrationStatusStage(stageobj);
end
