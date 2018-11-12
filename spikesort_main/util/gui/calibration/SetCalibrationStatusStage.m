% Takes a stage object as input, and updates the status "next," and
% "repeat" buttons accordingly

function SetCalibrationStatusStage(stageobj)
    global params cbpglobals;
    repeatbutton = findobj('Tag','calibration_sb_repeat');
    set(repeatbutton, 'String', ['Repeat: ' stageobj.name]);
    set(repeatbutton, 'Callback', @(varargin) CBPStage(stageobj.name));
    set(repeatbutton, 'Enable', 'on');

    % Set Next button
    if stageobj.next
        nextbutton = findobj('Tag','calibration_sb_next');
        if ~stageobj.showreview
            set(nextbutton, 'String', ['Next: ' stageobj.next]);
        else
            set(nextbutton, 'String', ['Iterate: ' stageobj.next]);
        end
        set(nextbutton, 'Enable', 'on');
        set(nextbutton, 'Callback', @(varargin) CBPStage(stageobj.next));
    else
        nextbutton = findobj('Tag','calibration_sb_next');
        set(nextbutton, 'String', '(Last Stage)');
        set(nextbutton, 'Enable', 'off');
        set(nextbutton, 'Callback', @(varargin) 0);
    end

    % Set Review button
    reviewbutton = findobj('Tag','calibration_sb_review');
    if stageobj.showreview
        set(reviewbutton, 'Visible', 'on');
    else
        set(reviewbutton, 'Visible', 'off');
    end

    % Set Processing button
    params_button = findobj('Tag','calibration_sb_params');
    set(params_button, 'String', 'Params', ...
                       'BackgroundColor', [.94 .94 .94], ...
                       'Enable', 'on', ...
                       'FontWeight', 'normal');

    % Select correct params tab, if figure is open
    if ishghandle(params.plotting.params_figure)
        params_tg = findobj('Tag','params_tg');
        newtab = findobj('Tag',['params_t_' stageobj.paramname]);
        set(params_tg, 'SelectedTab', newtab);
    end

    % Set currently selected tab in globals
    cbpglobals.currselected = stageobj;

    % Draw all
    pause(0.01);
    drawnow;
end
