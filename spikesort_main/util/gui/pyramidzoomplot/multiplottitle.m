function multiplottitle(varargin)
    panel = getappdata(gca, 'panel');
    under_subplot = getappdata(panel, 'under_subplot');
    title(under_subplot, varargin{:}, 'Visible', 'on');
end
