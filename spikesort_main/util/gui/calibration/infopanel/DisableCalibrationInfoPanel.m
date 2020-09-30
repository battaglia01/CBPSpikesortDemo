% Temporarily disable info panel while stage is loading
% Usage: DisableCalibrationInfoPanel

function DisableCalibrationInfoPanel
    h = LookupTag('infopanel_cellplot');
    set(h, 'Enable', 'off');

    pause(0.01);
    drawnow;
end
