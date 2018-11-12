% Changes the current CBP stage.
% Handles all redrawing, tab updating, axis scrolling, etc.
% Writes to the terminal the new stage name, category, and description, then
% calls the stage's "main" function, then calls the "plot" function if
% we're in calibration mode, and then closes with the stage instructions.

function CBPStage(name)
    global params cbpglobals;

% -------------------------------------------------------------------------
% Clear tabs, redraw, update axes, update stage ind
    DisableAllCalibrationTabs;
    DisableCalibrationStatus;
    pause(.001); %needed to make sure everything clears
    drawnow;

    ClearStaleTabs(name);
    UpdateScrollAxes;
    pause(.001); %needed to make sure everything clears
    drawnow;

    stageobj = GetStageFromName(name);
    cbpglobals.currstagenum = stageobj.stagenum;

% -------------------------------------------------------------------------
% Display prompt, call main stage, plot, write stage instructions, update
% status
    fprintf('\n*** %s stage "%s": %s...\n\n', stageobj.category, ...
            stageobj.name, stageobj.description);
    stageobj.mainfun();

    if (params.general.calibration_mode)
        stageobj.plotfun();
    end

    fprintf('\n*** Done %s stage: "%s"\n', stageobj.category, stageobj.name);
    StageInstructions;

    % Put the status and tabs back
    SetCalibrationStatusStage(GetStageFromName(name));  % (also re-enables)
    EnableAllCalibrationTabs;