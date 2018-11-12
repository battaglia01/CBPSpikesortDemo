% Useful helper function - given a stage name, clears the corresponding stage
% tab and all tabs after, in one step.
function ind = ClearStaleTabs(name)
    global cbpglobals params;
    if ~params.general.calibration_mode
        return;
    end
        
    stageobj = GetStageFromName(name);
    for n = stageobj.stagenum:length(cbpglobals.stages)
        cbpglobals.stages{n}.plotfun('disable');
    end
end
