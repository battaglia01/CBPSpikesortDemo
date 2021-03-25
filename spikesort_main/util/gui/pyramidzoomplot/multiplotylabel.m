function multiplotylabel(varargin)
    panel = getappdata(gca, 'panel');
    under_subplot = getappdata(panel, 'under_subplot');
    ylabel(under_subplot, varargin{:}, 'Visible', 'on');
end
