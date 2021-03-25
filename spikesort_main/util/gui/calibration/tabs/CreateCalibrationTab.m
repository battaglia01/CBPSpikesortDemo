% Creates a new calibration tab if one with that name doesn't already
% exist. If it does, changes to the tab instead.
%
% function t = CreateCalibrationTab(name, stagename, varargin)
function t = CreateCalibrationTab(name, stagename, varargin)
    global CBPInternals;
    % First load up the figure and check the tab doesn't already exist.
    f = GetCalibrationFigure;
    tg = LookupTag('calibration_tg');
    tname = formattagname(name);
    ttest = LookupTag(tname);
    t = [];

    % If ttest is empty, tab doesn't exist yet, so create it.
    % If it does, delete all of its children and clear.
    if(isempty(ttest))
        t = uitab(tg, 'Title', ...
                  name, 'Tag', tname);
        setappdata(t, 'stageobj', GetStageFromName(stagename));
        RegisterTag(t);
    else
        t = ChangeCalibrationTab(name);
        delete(t.Children);
    end

    % Now change the selected tab, and give us a pair of axes to work with.
    tg.SelectedTab = t;
    p = uipanel(t);
    a = axes('Parent',p);

    % Also, update the currently selected tab stage
    CBPInternals.curr_selected_tab_stage = GetStageFromName(stagename);
    
    % Lastly, if tab group is disabled, set color to gray
    if ~getappdata(tg, "Enabled")
        set(t,"ForegroundColor",[0.5 0.5 0.5]);
        drawnow;
        pause(0.01);
    end
    
end
