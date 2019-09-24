function multiplotresize(panel)
    ax = getappdata(panel, 'mp_axes');
    N = length(ax);

    if ~isequal(class(panel), 'matlab.ui.Figure')
        maxpos = getappdata(panel, 'scaledpos');
    end

    % now rearrange plots
    has_header = isequal(getappdata(panel, 'has_header'), true);
    for n=1:N
        % header height is no larger than 17% of entire setup, no smaller
        % than 1/N
        header_height = min(.17, 1/N);
        if has_header && n==1
            left = maxpos(1);
            bottom = maxpos(2)+maxpos(4)*(1-header_height);
            width = maxpos(3);
            height = maxpos(4)*header_height;
        elseif has_header && n~=1
            left = maxpos(1);
            bottom = maxpos(2)+maxpos(4)*(1-header_height)*(N-n)/(N-1);
            width = maxpos(3);
            height = maxpos(4)*(1-header_height)/(N-1);
        else
            left = maxpos(1);
            bottom = maxpos(2)+maxpos(4)*(N-n)/N;
            width = maxpos(3);
            height = maxpos(4)/N;
        end
        set(ax(n), 'Position', [left bottom width height]);

        % the following goofy line fixes a MATLAB display bug
        % by "resetting" axes
        xlim(ax(n), xlim(ax(n)));
        ylim(ax(n), ylim(ax(n)));
    end
end
