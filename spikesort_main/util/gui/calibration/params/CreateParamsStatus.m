% Creates the params status bar.  You probably don't want to call this
% directly, but rather GetCalibrationStatus (which calls this).

function h = CreateParamsStatus
    global params;

    h = uipanel(figure(params.plotting.params_figure), ...
        'Tag', 'params_sb', 'Position', [0 0 1 0.075]);

    uicontrol(h, 'Tag', 'params_sb_reset', ...
                 'Style', 'pushbutton', ...
                 'FontSize', 14, ...
                 'String', 'Reset', ...
                 'Units', 'normalized', ...
                 'Position', [0.5 0 0.25 1], ...
                 'Callback', @(varargin) ResetParamsFigure);

    uicontrol(h, 'Tag', 'params_sb_save', ...
                 'Style', 'pushbutton', ...
                 'FontSize', 14, ...
                 'String', 'Save', ...
                 'Units', 'normalized', ...
                 'Position', [0.75 0 0.25 1], ...
                 'Callback', @(varargin) SaveParams);

    % add blank list of changed params to figure app data
    setappdata(figure(params.plotting.params_figure), 'changed', {});
end

function SaveParams
    global params;
    % make sure something has changed
    currchanged = getappdata(GetParamsFigure, 'changed');
    if isempty(currchanged)
        return;
    end

    % set param for each thing that has changed
    % also reset background color
    for n=1:length(currchanged)
        % get param info
        pname = currchanged{n};
        pedit = findobj('Tag',['value: ' pname]);
        pval = get(pedit, 'String');

        % set param
        if isempty(pval)
            pval = '[]';
        end
        eval([pname ' = ' pval ';']);

        % change UI
        set(pedit, 'BackgroundColor', [1 1 1]);
    end

    % reset list of changed things
    setappdata(GetParamsFigure, 'changed', {});
end
