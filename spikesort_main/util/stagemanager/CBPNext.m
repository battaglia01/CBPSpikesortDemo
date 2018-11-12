function CBPNext
    global cbpglobals;
    
    if isempty(cbpglobals.currstagenum)
        InitAllStages;
    elseif cbpglobals.currstagenum == 0
        CBPStage(cbpglobals.stages{1}.name);
    else
        assert(~isempty(cbpglobals.stages{cbpglobals.currstagenum}.next), 'ERROR: This is the last stage!');
        CBPStage(cbpglobals.stages{cbpglobals.currstagenum}.next);
    end
end