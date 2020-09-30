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
        pname = char(currchanged{n});
        pedit = LookupTag(['params_value_' strrep(pname, '.', '___')]);
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