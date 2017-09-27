<<<<<<< HEAD
function t = GetCalibrationTab(name)
    tg = findobj('Tag','calibration_tg');
    t = findobj('Tag',['calibration_t_' name]);
    
    if(~isempty(tg) && ~isempty(t))
        GetCalibrationFigure;
        tg.SelectedTab = t;
    end
=======
function [t,a] = GetCalibrationTab(name)
    tg = findobj('Tag','calibration_tg');
    t = findobj('Tag',['calibration_t_' name]);
    
    if(~isempty(tg) && ~isempty(t))
        GetCalibrationFigure;
        tg.SelectedTab = t;
        for n=t.Children
            if(isequal(class(n),'matlab.graphics.axis.Axes'))
                a = n;
                axes(a);
                return;
            end
        end;
        %if we got here, there are no axes
        a = axes('parent',t);
    end
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
end