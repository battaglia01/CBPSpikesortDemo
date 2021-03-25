% Callback when user changes a textbox
function ParamChanged(obj, data)
    global params;

    pname = char(get(obj, 'Tag'));  % cast to char just to make sure it isn't a string
    pname = pname(14:end);          % truncate initial "params_value_" string
    pname = strrep(pname, '___', '.');
    oldpvalue = eval(pname);

    oldstr = ConvertParamToStr(oldpvalue);
    newstr = get(obj,'String');

    currchanged = getappdata(GetParamsFigure, 'changed');

    % if string has changed, change background color and add to list
    % of changed
    if ~isequal(oldstr, newstr) && ~(isempty(oldstr) && isempty(newstr))
        set(obj, 'BackgroundColor', [1 1 0.4]);

        % check if this is already listed as changed
        found = false;
        for n=1:length(currchanged)
            if isequal(currchanged{n}, pname)
                found = true;
            end
        end

        % if not, list it as changed
        if ~found
            currchanged{end+1} = pname;
        end
    else
        % Set back to default background color
        %%@ NOTE - this is default in MATLAB, should double check it works
        %%@ for all LAF's
        set(obj, 'BackgroundColor', [1 1 1]);

        % find this in the changed list
        currchanged = getappdata(GetParamsFigure, 'changed');
        found = false;
        foundind = -1;
        for n=1:length(currchanged)
            if isequal(currchanged{n}, pname)
                found = true;
                foundind = n;
            end
        end

        % if we found something, remove it from the list
        if found
            currchanged(foundind) = [];
        end
    end

    % now make a note of changed things
    setappdata(GetParamsFigure, 'changed', currchanged);
end