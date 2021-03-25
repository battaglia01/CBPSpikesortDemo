% This is a helper function that calls "func(varargin{:})" on each individual plot
% in the multiplot.
%
% Example:
%   multiplotsubfunc(@ylim,[-1 1]) calls ylim([-1 1]) on each individual subplot
function multiplotsubfunc(func,varargin)
    panel = getappdata(gca, 'panel');
    ax = getappdata(panel, 'mp_axes');
    for n=1:length(ax)
        if ~isequal(getappdata(ax(n), ['ignore_' char(func)]), true)
            func(ax(n), varargin{:});
        end
    end
end
