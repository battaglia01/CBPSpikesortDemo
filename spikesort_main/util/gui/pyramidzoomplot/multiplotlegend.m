function out = multiplotlegend(varargin)
    % get axes
    panel = getappdata(gca, 'panel');
    ax = getappdata(panel, 'mp_axes');
    N = length(ax);

    % search for location
    location = 'northeast';
    for n=1:length(varargin)
        if isequal(varargin{n}, 'Location')
            location = varargin{n+1};
        end
    end
    if ~contains(lower(location), 'north') && ~contains(lower(location), 'south')
        error('ERROR: multiplot legend must contain north or south');
    end

    % get plots
    plt = gobjects(0);
    for n=1:length(ax)
        c = get(ax(n), 'Children');
        for m=1:length(c)
            %%@if ~isequal(get(c(m), 'HandleVisibility'), 'off')
                %%@ Commenting the above because MATLAB should do it
                plt = [c(m);plt];       % MATLAB stores backward for some reason
            %%@end
        end
    end

    % do legend
    if contains(lower(location), 'north')
        out = legend(ax(1), plt, varargin{:});
        uistack(ax(1), 'top');
    elseif contains(lower(location), 'south')
        out = legend(ax(end), plt, varargin{:});
        uistack(ax(end), 'top');
    end

    % change bounding box and resize
    drawnow;        %so it updates correctly
    pause(0.01);
    newmaxpos = [Inf Inf 0 0];
    for n=1:length(ax)
        tmppos = get(ax(n), 'Position');
        newmaxpos(1:2) = min(newmaxpos(1:2), tmppos(1:2));
        newmaxpos(3:4) = max(newmaxpos(3:4), tmppos(1:2)+tmppos(3:4));
    end
    newmaxpos(3:4) = newmaxpos(3:4) - newmaxpos(1:2);
    setappdata(panel, 'scaledpos', newmaxpos);
    multiplotresize(panel);
end
