% Disables all the calibration tabs.

function DisableAllCalibrationTabs
    global CBPInternals;
%%@ saved from previous; this is MATLAB's java-based method to disable
%%@ tabs
%     if isfield(CBPInternals, 'tabbedpaneref')
%         CBPInternals.tabbedpaneref.setEnabled(0);
%     else
%         f = GetCalibrationFigure;
%         jtg = findjobj(f, 'class', 'JTabbedPane');
%         jtg.setEnabled(0);
%         CBPInternals.tabbedpaneref = jtg;
%     end

    % get tabgroup handle
    tg = LookupTag("calibration_tg");

    % set our custom appdata enabled flag to false, which is important when
    % switching
    setappdata(tg, "Enabled", false);

    % iterate through all the children and change the color
    tabs = get(tg, "Children");
    for n=1:length(tabs)
        set(tabs(n), "ForegroundColor", [0.5 0.5 0.5]);
    end

    % That's it. The rest is done in CreateCalibrationFigure's "TabChanged"
    % function
end