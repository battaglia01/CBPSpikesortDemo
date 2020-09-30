% Auxiliary function to call the "plotfun" for a certain CBP stage, given
% its name.
% It is generally better to call this function than to call the plotfun
% directly, because it does some cleanup also needed before plotting
% (example: sets window as modal)

function CBPStagePlot(stageobj)
    global params CBPInternals;

% -------------------------------------------------------------------------
% Assert calibration mode is on, and if so, get stageobj
    assert(params.plotting.calibration_mode, ...
           "Can only call CBPStagePlot if Calibration mode is on!");

% -------------------------------------------------------------------------
% Set Calibration Loading, set scroll axes
    SetCalibrationLoading(true);
    pause(.001); %needed to make sure everything clears
    drawnow;

%%@ this is off for now but may be good
%     UpdateScrollAxes;
%     pause(.001); %needed to make sure everything clears
%     drawnow;

% -------------------------------------------------------------------------
% Plot stage, catch errors, reset status
    % if this flag is set, don't do the try-catch. useful for error
    % debugging
    if params.general.raw_errors
        plot_stage(stageobj);
    else
        try
            plot_stage(stageobj);
        catch err
            % reset CalibrationLoading
            SetCalibrationLoading(false);

            % make window non-modal again
            set(GetCalibrationFigure, "WindowStyle", "normal");

            errordlg(sprintf("There was an error while plotting.\n" + ...
                             "Often, this is because a parameter adjustment " + ...
                             "is needed. If this is true, change parameters " + ...
                             "and rerun the current stage!\n" + ...
                             "\n" + ...
                             "Error message is below:\n" + ...
                             "===\n%s\n" + ...
                             "===\n\nMore detail in the command window.", ...
                             err.message), "Processing Error", "modal");
            rethrow(err);
        end
    end

    % Reset the `needsreplot` setting for the stage we just plotted.
    % Since stages are subclasses of handle, changing it here auto-changes it
    % everywhere
    stageobj.needsreplot = false;

    % Put the status and tabs back, and as a precaution, reset LaF
    SetCalibrationLoading(false);
    %%@ javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);
%%@ ^^ NOTE: Metal no longer works on Mac R2019, so not necessary
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% aux function to run a stage
function plot_stage(stageobj)
    global params
    % make window modal. this makes sure the user doesn't change windows
    % mid-plot
    set(GetCalibrationFigure, "WindowStyle", "modal");
    stageobj.plotfun();
    set(GetCalibrationFigure, "WindowStyle", "normal");
end
