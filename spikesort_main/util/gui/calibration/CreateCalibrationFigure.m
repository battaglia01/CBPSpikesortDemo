% Creates the Calibration figure. Called by GetCalibrationFigure.
% If you want to create the Calibration figure in the program, 
% you usually want to call GetCalibrationFigure, not this.

function h = CreateCalibrationFigure
    global params dataobj;

% ================================================================
% First, get the calibration figure
    h = figure(params.plotting.calibration_figure);

    %Set look and feel. Taken from
    %http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    originalLnF = javax.swing.UIManager.getLookAndFeel;
    javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');

    %If it doesn't already exist, create it
    h = figure(params.plotting.calibration_figure);
    h.NumberTitle = 'off';

    %may not have filename yet
    h.Name = 'Calibration';

    %Set up basic initial features
    set(gcf, 'ToolBar', 'none');
    scrsz =  get(0,'ScreenSize');
    set(gcf, 'OuterPosition', [0.05*scrsz(3) 0.10*scrsz(4) .9*scrsz(3) .85*scrsz(4)]);

    %Set up tab group
    tg = uitabgroup(h, 'Tag', 'calibration_tg', ...
                       'SelectionChangedFcn', ...
                            @(varargin) SetCalibrationStatusStage(get(varargin{2}.NewValue,'UserData')), ... %2 is new tab
                       'TabLocation', 'left', ...
                       'Position', [0 0.05 1 0.95]);

    %Create status bar and disable until a stage is set
    sb = GetCalibrationStatus;
    DisableCalibrationStatus;

    %Add button up callback (needed for Amplitude Threshold Stage)
    iptaddcallback(gcf, 'WindowButtonUpFcn', @ThresholdWindowButtonUp);

    %Ensure that the controls are fully-rendered before restoring the L&F
    drawnow;
    pause(0.05);

    %Restore original look and feel
    javax.swing.UIManager.setLookAndFeel(originalLnF);
end
