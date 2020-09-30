% Temporarily disable status bar while stage is loading
% Usage: DisableCalibrationStatus
%
function DisableCalibrationStatus
    optionbutton = LookupTag('calibration_sb_options');
    set(optionbutton, 'String', 'Processing...', ...
                      'FontWeight', 'bold', ...
                      'Visible', 'on', ...
                      'BackgroundColor', [1 .5 .5], ...
                      'Enable', 'inactive');

    repeatbutton = LookupTag('calibration_sb_repeat');
    set(repeatbutton, 'String', 'Loading...');
    set(repeatbutton, 'Enable', 'off');

    nextbutton = LookupTag('calibration_sb_next');
    set(nextbutton, 'String', 'Status in Command Window...');
    set(nextbutton, 'Enable', 'off');

    reviewbutton = LookupTag('calibration_sb_review');
    set(reviewbutton, 'Visible', 'off');

    pause(0.01);
    drawnow;
end
