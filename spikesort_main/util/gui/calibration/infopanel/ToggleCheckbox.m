% Store on/off status in UserData
function out = ToggleCheckbox(parent, varargin)
    % create control with some specialized stuff
    out = uicontrol(parent, 'Style', 'PushButton', ...
                             varargin{:}, ...
                            'FontWeight', 'bold', ...
                            'FontUnits', 'normalized', ...
                            'FontSize', 0.8);
    set(out, 'Callback', @(varargin) toggleCallback(out));
                        
	% double check val is 0 or 1
    val = get(out, 'UserData');
    if isempty(val) || ((val ~= 0) && (val ~= 1))
        set(out, 'UserData', 0);
    end
    
    % initialize the toggle string (√ or nothing)
    updateToggleString(out);
end

function updateToggleString(src)
    % if background color is too dark, invert checkbox
    backcolor = get(src, 'BackgroundColor');
    lightness = rgb2gray(backcolor);
    if lightness(1) < 0.5
        set(src, 'ForegroundColor', 'white');
    else
        set(src, 'ForegroundColor', 'black');
    end

    % now change the string accordingly
    val = get(src,'UserData');
    if val == 0
        set(src,'String','');
    else
        set(src,'String','√');
    end
end

% called when the button is toggled. updates string and calls custom user
% callback (if applicable)
function toggleCallback(src)
    % note we are storing the value in UserData. 1 is checked, 0 is not
    val = get(src,'UserData');
    if val == 0
        set(src,'UserData',1);
    else
        set(src,'UserData',0);
    end
    
    updateToggleString(src);
    
    % call custom callback if applicable
    callbackfun = getappdata(src, 'togglecallback');
    if ~isempty(callbackfun)
        callbackfun();
    end
end