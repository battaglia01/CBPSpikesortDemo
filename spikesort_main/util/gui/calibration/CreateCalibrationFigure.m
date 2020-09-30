% Creates the Calibration figure. Called by GetCalibrationFigure.
% If you want to create the Calibration figure in the program,
% you usually want to call GetCalibrationFigure, not this.

function h = CreateCalibrationFigure
    global CBPdata params CBPInternals;

% ================================================================
% First, get the calibration figure
    % Set look and feel. Taken from
    % http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    %%%@ javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');
    %%@ ^^ NOTE: Metal no longer works on Mac R2019, so just use the default

    % If it doesn't already exist, create it
    h = figure(params.plotting.calibration_figure);
    h.NumberTitle = 'off';

    % may not have filename yet
    h.Name = 'Calibration';

    % Set up basic window features
    set(h, 'ToolBar', 'none');
    set(h, 'MenuBar', 'none');
    scrsz =  get(0,'ScreenSize');
    set(h, 'OuterPosition', [0.05*scrsz(3) 0.075*scrsz(4) .9*scrsz(3) .85*scrsz(4)]);
    set(h, 'CloseRequestFcn', @ConfirmCloseCalibrationFigure);
    
    % Set up info panel
    info = GetCalibrationInfoPanel;

    % Set up tab group
    %%@ Change LookAndFeel to metal just for the tabgroup
    javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');
    tg = uitabgroup(h, 'Tag', 'calibration_tg', ...
                       'SelectionChangedFcn', ...
                       @(varargin) TabChanged(varargin{:}), ...
                       'TabLocation', 'left', ...
                       'Position', [0 0.05 1 0.91]);
    %%@ Since MATLAB is deprecating java, try a different way to enable/disable
    %%@ tabgroup
    setappdata(tg, "Enabled", true);
    javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);

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
    %%@ javax.swing.UIManager.setLookAndFeel(CBPInternals.originalLnF);
    %%@ ^^ NOTE: Metal no longer works on Mac R2019, so not necessary
end



% Taken from MATLAB's example documentation
function ConfirmCloseCalibrationFigure(src,callbackdata)
% Close request function 
% to display a question dialog box 
   selection = questdlg("Are you sure you want to close the calibration " + ...
                        "window? If you haven't saved, you will lose " + ...
                        "your results.", ...
                        'Close Request Function', ...
                        'Yes', 'No', 'No'); 
   switch selection 
      case 'Yes'
         delete(gcf)
      case 'No'
      return 
   end
end