% Changes the current CBP stage.
% Handles all redrawing, tab updating, axis scrolling, etc.
% Writes to the terminal the new stage name, category, and description, then
% calls the stage's "main" function, then calls the "plot" function if
% we're in calibration mode, and then closes with the stage instructions.

function CBPStage(name)
    global CBPdata params CBPInternals;

% -------------------------------------------------------------------------
% Update internal stage
    stageobj = GetStageFromName(name);

    oldrecentstage = CBPInternals.most_recent_stage;
    oldselectedtabstage = CBPInternals.curr_selected_tab_stage;

    CBPInternals.most_recent_stage = stageobj;
    CBPInternals.curr_selected_tab_stage = oldselectedtabstage;
    CBPdata.last_stage_name = stageobj.name;
    
    % always make sure most_recent_stage is at the top
    CBPdata_fieldnames = fieldnames(CBPdata);
    indC = strfind(CBPdata_fieldnames,'last_stage_name');
    ind = find(not(cellfun('isempty',indC)));
    newperm = [ind setdiff(1:length(CBPdata_fieldnames), ind)];
    CBPdata = orderfields(CBPdata, newperm);
    
% -------------------------------------------------------------------------
% Clear tabs, redraw, update axes
    if isfield(params, 'plotting') && ...
       isfield(params.plotting, 'calibration_mode') && ...
       params.plotting.calibration_mode

        SetCalibrationLoading(true);
        pause(.001); %needed to make sure everything clears
        drawnow;

        ClearStaleTabs(name);
        UpdateScrollAxes;
        pause(.001); %needed to make sure everything clears
        drawnow;
    end

% -------------------------------------------------------------------------
% Display prompt, call main stage, plot, write stage instructions, update
% status
    % if this flag is set, don't do the try-catch. useful for error
    % debugging
    if params.general.raw_errors
        run_stage(stageobj);
    else
        try
            run_stage(stageobj);
        catch err
            if params.plotting.calibration_mode
                % undo half-finished plots
                ClearStaleTabs(name);

                % set the last stage
                if ~isempty(oldrecentstage) % means we didn't just crash in raw_data
                    % get the last tab remaining, which is the stage we should
                    % go to. (Not necessarily the last stage - if we are
                    % redoing an earlier stage than the last one computed, then
                    % if it crashes, we don't want to try to return to the (now
                    % obsolete) future stage
                    tg = findall(groot, "Tag", "calibration_tg");
                    last_stage =  getappdata(get(tg, "SelectedTab"), 'stageobj');
                    CBPInternals.most_recent_stage = last_stage;
                    CBPInternals.curr_selected_tab_stage = last_stage;
                    CBPdata.last_stage_name = last_stage.name;
                    SetCalibrationLoading(false);
                end

                % make window non-modal again
                set(GetCalibrationFigure, "WindowStyle", "normal");
            end

            errordlg(sprintf("There was an error while processing.\n" + ...
                             "Often, this is because a parameter adjustment " + ...
                             "is needed. If this is true, change parameters " + ...
                             "and try again!\n" + ...
                             "\n" + ...
                             "Error message is below:\n" + ...
                             "===\n%s\n" + ...
                             "===\n\nMore detail in the command window.", ...
                             err.message), "Processing Error", "modal");
            rethrow(err);
        end
    end


    % Put the status and tabs back, and as a precaution, reset LaF
    if params.plotting.calibration_mode
        SetCalibrationLoading(false);
    end
    %%@ javax.swing.UIManager.setLookAndFeel(CBPInternals.original_LnF);
%%@ ^^ NOTE: Metal no longer works on Mac R2019, so not necessary
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% aux function to run a stage
function run_stage(stageobj)
    global params
    fprintf('\n*** %s stage "%s": %s...\n\n', stageobj.category, ...
            stageobj.name, stageobj.description);
    stageobj.mainfun();

    if params.plotting.calibration_mode
    % make window modal. this makes sure the user doesn't change windows
    % mid-plot
        set(GetCalibrationFigure, "WindowStyle", "modal");
        stageobj.plotfun();
        set(GetCalibrationFigure, "WindowStyle", "normal");
    end

    fprintf('\n*** Done %s stage: "%s"\n', stageobj.category, ...
            stageobj.name);
    StageInstructions;
end
