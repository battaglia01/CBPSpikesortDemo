% GetCalibrationFigure returns a handle to the current calibration figure.
% If the figure doesn't already exist, it calls CreateCalibrationFigure and
% creates one. Also creates the TabGroup and Status Bar.
%
% This also auto-updates the title bar when the filename is specified.

function h = GetCalibrationFigure
    global params dataobj;

% ================================================================
% First, check to see if it already exists and set h accordingly
    if ishghandle(params.plotting.calibration_figure)
        h = figure(params.plotting.calibration_figure);
    else
        h = CreateCalibrationFigure;
    end
    

% ================================================================
% Update titlebar in the event a filename is present
    if isfield(dataobj,'filename')
        filenameindex = max(strfind(dataobj.filename,'/'));
        if isempty(filenameindex)
            filenameindex = 0;
        end
        shortname = dataobj.filename(filenameindex+1:end);
        set(h,'Name', [shortname ' - Calibration']);
    end