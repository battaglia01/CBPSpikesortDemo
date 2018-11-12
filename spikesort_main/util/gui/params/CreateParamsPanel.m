% Creates the parameter UI panel for a particular param field.
% This is called by CreateParamsFigure.
% The second parameter is the parent tab to attach the panel to.

function p = CreateParamsPanel(fieldname, parent)
    global params;
    
    % First construct uipanel
    p = uipanel('Parent', parent, ...
                'Tag', ['params_panel_' fieldname], ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
            
    % Now add textboxes for each field
    field = getfield(params,fieldname);
    subfields = fieldnames(field);
    for n=1:length(subfields)
        subfieldname = subfields(n);
        subfieldname = subfieldname{1};
        
        subfieldlabel = uicontrol('Parent', p, ...
                                  'Tag', ['label: params.' fieldname '.' subfieldname], ...
                                  'Style', 'edit', ...
                                  'Enable', 'inactive', ...
                                  'String', subfieldname, ...
                                  'HorizontalAlignment', 'right', ...
                                  'Units', 'normalized', ...
                                  'Position', [.05 1-.06*n .35 .05], ...
                                  'FontUnits', 'normalized', ...
                                  'FontSize', .67);
                              
        subfieldentry = uicontrol('Parent', p, ...
                                  'Tag', ['value: params.' fieldname '.' subfieldname], ...
                                  'Style', 'edit', ...
                                  'String', ConvertParamToStr(getfield(field,subfieldname)), ...
                                  'HorizontalAlignment', 'left', ...
                                  'Units', 'normalized', ...
                                  'Position', [.4125 1-.06*n .55 .05], ...
                                  'FontUnits', 'normalized', ...
                                  'FontSize', .67, ...
                                  'Callback', @ParamChanged);
    end
end

% Callback when user changes a textbox
function ParamChanged(obj, data)
    global params;
    
    pname = get(obj, 'Tag');
    pname = pname(8:end);       %truncate initial "value: " string
    oldpvalue = eval(pname);
    
    oldstr = ConvertParamToStr(oldpvalue);
    newstr = get(obj,'String');
    
    currchanged = getappdata(GetParamsFigure, 'changed');
    
    % if string has changed, change background color and add to list
    % of changed
    if ~isequal(oldstr, newstr) && ~(isempty(oldstr) && isempty(newstr))
        set(obj, 'BackgroundColor', [1 0.4 0.4]);
        
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
    
    % now update currchanged, and if anything is in it, set "Save" status
    % accordingly
    setappdata(GetParamsFigure, 'changed', currchanged);
    
    savebutton = findobj('Tag','params_sb_save');
    if isempty(currchanged)
        set(savebutton, 'Enable', 'off');
    else
        set(savebutton, 'Enable', 'on');
    end
end