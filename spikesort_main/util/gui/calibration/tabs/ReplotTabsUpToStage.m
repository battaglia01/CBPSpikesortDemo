% Useful helper function - given a stage name, replots all previous stages up to
% and including the stage.
function ind = ReplotTabsUpToStage(name)
    global CBPInternals params;
    if ~params.plotting.calibration_mode
        return;
    end

    stageobj = GetStageFromName(name);
    for n = 1:stageobj.stagenum
        CBPInternals.stages{n}.plotfun();
    end
end
