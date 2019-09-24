function multiplotdummyfunc(func,varargin)
    panel = getappdata(gca, 'panel');
    sub = getappdata(panel, 'under_subplot');
    func(sub, varargin{:});
end
