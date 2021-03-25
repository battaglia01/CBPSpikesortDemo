% This is a helper function that prevents certain functions from being called via
% "multiplotsubfunc" for some subplot axis n.
%
% Example:
%   multiplotsubignorefunc(@ylim,1) says that future calls to
%   multiplotsubfunc(@ylim,...) will not propagate to subplot axis #1.
function multiplotsubignorefunc(func,n)
    panel = getappdata(gca, 'panel');
    ax = getappdata(panel, 'mp_axes');
    setappdata(ax(n), ['ignore_' char(func)], true);
end
