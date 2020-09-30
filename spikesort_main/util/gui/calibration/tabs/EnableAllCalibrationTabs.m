% Enables all the calibration tabs.

function EnableAllCalibrationTabs
%     global CBPInternals;
%     if isfield(CBPInternals, 'tabbedpaneref')
%         CBPInternals.tabbedpaneref.setEnabled(1);
%     else
%         f = GetCalibrationFigure;
%         jtg = findjobj(f, 'class', 'JTabbedPane');
%         jtg.setEnabled(1);
%         CBPInternals.tabbedpaneref = jtg;
%     end

    % get tabgroup handle
    tg = LookupTag("calibration_tg");

    % set our custom appdata enabled flag to false, which is important when
    % switching
    setappdata(tg, "Enabled", true);

    % iterate through all the children and change the color back to black
    tabs = get(tg, "Children");
    for n=1:length(tabs)
        set(tabs(n), "ForegroundColor", [0 0 0]);
    end
    
    % That's it. The rest is done in CreateCalibrationFigure's "TabChanged"
    % function
end
