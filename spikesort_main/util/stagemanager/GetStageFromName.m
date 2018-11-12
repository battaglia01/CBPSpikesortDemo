% Returns a stage object from the current name
function stageobj = GetStageFromName(name)
    global cbpglobals;
    stageobj = [];
    for n=1:length(cbpglobals.stages)
        if isequal(cbpglobals.stages{n}.name, name)
            stageobj = cbpglobals.stages{n};
            return;
        end
    end
end
