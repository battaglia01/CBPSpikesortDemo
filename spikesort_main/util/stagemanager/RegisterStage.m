function RegisterStage(stagename, nextstage, plotfun, category)
    global cbpglobals;
    currstage = [];
    currstage.currfun = stagename;
    currstage.nextfun = nextstage;
    currstage.plotfun = plotfun;
    currstage.category = category;
    cbpglobals.stages{end+1} = currstage;
end
