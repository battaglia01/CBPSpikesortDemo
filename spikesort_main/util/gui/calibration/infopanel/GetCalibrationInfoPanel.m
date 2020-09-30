% Returns a handle to the calibration info panel.
% If it doesn't exist, create it.

function h = GetCalibrationInfoPanel
    global params;

    h = LookupTag('calibration_info');
    if isempty(h)
        h = CreateCalibrationInfoPanel;
    end
end
