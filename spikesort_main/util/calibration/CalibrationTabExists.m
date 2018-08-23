function status = CalibrationTabExists(name)
    tg = findobj('Tag','calibration_tg');
    t = findobj('Tag',['calibration_t_' name]);
    
    if(~isempty(tg) && ~isempty(t))
        status = true;
    else
        status = false;
    end
end