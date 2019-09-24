% Re-enable status bar at last stage.
% Usage: EnableCellInfoStatus
function EnableCellInfoStatus
    h = findobj('Tag','infopanel_cellplot');
    set(h, 'Enable', 'on');

    pause(0.01);
    drawnow;
end
