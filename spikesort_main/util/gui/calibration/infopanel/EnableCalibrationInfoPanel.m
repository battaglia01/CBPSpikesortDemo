% Re-enable status bar at last stage.
% Usage: EnableCalibrationInfoPanel
function EnableCalibrationInfoPanel
    h = LookupTag('infopanel_cellplot');
    set(h, 'Enable', 'on');

    pause(0.01);
    drawnow;
end
