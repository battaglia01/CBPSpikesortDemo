% Useful helper function - given a stage name, clears the corresponding stage
% tab and all tabs after, in one step.
function ind = ClearStaleTabs(name)
    global CBPInternals params;
    if ~params.plotting.calibration_mode
        return;
    end
        
    stageobj = GetStageFromName(name);
    for n = stageobj.stagenum:length(CBPInternals.stages)
        CBPInternals.stages{n}.plotfun('disable');
    end
end
