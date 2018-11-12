function CBPRepeat
    global cbpglobals;
    oldstage = cbpglobals.stages{cbpglobals.currstagenum}.name;
    CBPStage(oldstage);
end
