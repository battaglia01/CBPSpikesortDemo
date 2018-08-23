function CBPNext
    global cbpglobals;
    if isempty(cbpglobals.currstageind)
        InitStage;
    else
        nextstage = cbpglobals.stages{cbpglobals.currstageind}.nextfun;
        nextstage();
    end
end
