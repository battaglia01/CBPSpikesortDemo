function CBPNext
    global cbpglobals;
    oldstage = cbpglobals.stages{cbpglobals.currstageind}.currfun;
    oldstage();
end
