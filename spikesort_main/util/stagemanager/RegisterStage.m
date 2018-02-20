function RegisterStage(stagename, nextstage, plotfun)
    global stages;
    stages{end+1} = {stagename, nextstage, plotfun};
end