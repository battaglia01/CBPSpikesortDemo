% RegisterStage adds a stage to the StageManager. You specify the stage's
% name, the next stage, the stage's plot function, the stage's category
% (such as "preprocessing"), and then a variable number of arguments
% for different buttons with callbacks

function RegisterStage(stageobj)
    global cbpglobals;
    stageobj.mainfun = eval(['@' stageobj.name 'Main']);
    stageobj.plotfun = eval(['@' stageobj.name 'Plot']);
    stageobj.nextfun = eval(['@' stageobj.next 'Main']);
    stageobj.stagenum = length(cbpglobals.stages)+1;
    
    % This is for the last CBP stage, so we can change the status bar
    % accordingly to show "iterate" and "review" buttons
    if ~isfield(stageobj, 'showreview')
        stageobj.showreview = false;
    end
    cbpglobals.stages{end+1} = stageobj;
end
