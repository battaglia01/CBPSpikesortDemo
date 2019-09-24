% Returns a stage object from the current name
function stageobj = GetStageFromName(name)
    global CBPInternals;
    stageobj = [];
    for n=1:length(CBPInternals.stages)
        if isequal(CBPInternals.stages{n}.name, name)
            stageobj = CBPInternals.stages{n};
            return;
        end
    end
end
