% Returns a handle to the calibration status bar.
% If it doesn't exist, create it.

function h = GetCalibrationStatus
    global params;

    h = LookupTag('calibration_sb');
    if isempty(h)
        h = CreateCalibrationStatus;
    end
end
