% Creates the Calibration figure. Called by GetCalibrationFigure.
% If you want to create the Calibration figure in the program,
% you usually want to call GetCalibrationFigure, not this.

function h = CreateCalibrationFigure
    global CBPdata params CBPInternals;

% ================================================================
% First, get the calibration figure
    h = figure(params.plotting.calibration_figure);

    % Set look and feel. Taken from
    % http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');

    % If it doesn't already exist, create it
    h = figure(params.plotting.calibration_figure);
    h.NumberTitle = 'off';

    % may not have filename yet
    h.Name = 'Calibration';

    % Set up basic window features
    set(h, 'ToolBar', 'none');
    set(h, 'MenuBar', 'none');
    scrsz =  get(0,'ScreenSize');
    set(h, 'OuterPosition', [0.05*scrsz(3) 0.10*scrsz(4) .9*scrsz(3) .85*scrsz(4)]);

    % Set up info panel
    info = GetCalibrationInfoPanel;

    % Set up tab group
    tg = uitabgroup(h, 'Tag', 'calibration_tg', ...
                       'SelectionChangedFcn', ...
                       @(varargin) TabChanged(varargin{:}), ...
                       'TabLocation', 'left', ...
                       'Position', [0 0.05 1 0.91]);

    % Store handle to this in figure's appdata so we don't need to look
    % every time
    RegisterTag(tg);

    % Create status bar
    sb = GetCalibrationStatus;

    % Disable everything at first until a stage is set
    SetCalibrationLoading(true);

    % Add button up callback (does several things, such as
    % update Amplitude Threshold Stage if necessary
    iptaddcallback(h, 'WindowButtonUpFcn', @WindowButtonUp);

    % Ensure that the controls are fully-rendered before restoring the L&F
    drawnow;
    pause(0.05);

    % Restore original look and feel
    javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);
end

% varargin{1} is the tabgroup, varargin{2} is a struct w/ the OldValue and
% NewValue
function TabChanged(varargin)
    global CBPInternals;
    % first, update the internal "currselectedtabstage"
    newstageobj = getappdata(varargin{2}.NewValue, 'stageobj');
    CBPInternals.currselectedtabstage = newstageobj;

    % now set the new calibration status
    SetCalibrationStatusStage(newstageobj);

    % Then, if "needsreplot" is set in the current stage, replot and reset.
    % Note this updates the true stage object, since stages are subclasses
    % of handle
    if newstageobj.needsreplot
        CBPStagePlot(newstageobj);
        CBPInternals.currselectedtabstage.needsreplot = false;
        newstageobj.needsreplot = false;
    end
end
