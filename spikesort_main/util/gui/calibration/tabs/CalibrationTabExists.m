function status = CalibrationTabExists(name)
    f = GetCalibrationFigure;
    tg = LookupTag('calibration_tg');
    tname = formattagname(name);
    t = LookupTag(tname);

    if(~isempty(tg) && ~isempty(t))
        status = true;
    else
        status = false;
    end
end
