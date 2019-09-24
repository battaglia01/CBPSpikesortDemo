% This function is called when someone clicks on the figure.
%
% For now, all it does is check if the options menu is open (and close it),
% and also pass to the ThresholdWindowButtonUp.
function WindowButtonUp(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clear options menu if open
%%@ seems unnecessary?

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run ThresholdWindowButtonUp
    % First check if tab exists
    if ~CalibrationTabExists('CBP Threshold Adjustment')
        return;
    end

    % Then check it's selected
    f = GetCalibrationFigure;
    tg = LookupTag('calibration_tg');
    currtab = get(tg,'SelectedTab');
    if ~isequal(currtab.Title, 'CBP Threshold Adjustment')
        return;
    end

    % If we made it this far, call ThresholdWindowButtonUp
    ThresholdWindowButtonUp(varargin{:})
end
