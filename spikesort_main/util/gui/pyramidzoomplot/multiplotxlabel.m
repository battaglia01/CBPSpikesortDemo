function multiplotxlabel(varargin)
    panel = getappdata(gca, 'panel');
    under_subplot = getappdata(panel, 'under_subplot');
    xlabel(under_subplot, varargin{:}, 'Visible', 'on');
end
