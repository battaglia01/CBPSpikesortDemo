function ThresholdWindowButtonUp(varargin)
global dataobj;

    %First check if tab exists
    if ~CalibrationTabExists('CBP Threshold Adjustment')
        return;
    end

    %Then check it's selected
    tg = findobj('Tag','calibration_tg');
    currtab = get(tg,'SelectedTab');
    if ~isequal(currtab.Title, 'CBP Threshold Adjustment')
        return;
    end

    %If we've gotten this far, process it!
    %Timer makes drawing easier
    for i=1:length(dataobj.CBPinfo.spike_amps)
        t = timer;
        t.StartDelay = .2;
        t.TimerFcn = @(~,~) UpdateThresh(i, GetCalibrationFigure);
        start(t)
    end
end
