% RegisterStage adds a stage to the StageManager. You specify the stage's
% name, the next stage, the stage's plot function, the stage's category
% (such as "preprocessing"), and then a variable number of arguments
% for different buttons with callbacks

function RegisterStage(stageobj)
    global CBPInternals;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set main and plot functions, as well as stagenum
    stageobj.mainfun = eval(['@' stageobj.name 'Main']);
    stageobj.plotfun = eval(['@' stageobj.name 'Plot']);
    stageobj.nextfun = eval(['@' stageobj.next 'Main']);
    stageobj.stagenum = length(CBPInternals.stages)+1;
%     stageobj.needsreplot = false;   % this is set to true when the cell plot changes
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set some default params if they aren't explicitly stated
%     % This is to determine if we replot once the chosen cells change (from
%     % the CellInfoPlot). If this isn't explicitly set to true, assume we
%     % don't replot
%     if ~isfield(stageobj, 'replotoncellchange')
%         stageobj.replotoncellchange = false;
%     end
%     
%     % This is for the last CBP stage, so we can change the status bar
%     % accordingly to show "iterate" and "review" buttons
%     if ~isfield(stageobj, 'showreview')
%         stageobj.showreview = false;
%     end
    
    
    CBPInternals.stages{end+1} = stageobj;
end
