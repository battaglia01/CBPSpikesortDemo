% Temporarily disable info panel while stage is loading
% Usage: DisableCalibrationInfoPanel

function DisableCalibrationInfoPanel
    h = findobj('Tag','infopanel_cellplot');
    set(h, 'Enable', 'off');

    pause(0.01);
    drawnow;
end
