function h = GetVerifyFigure
global params dataobj;
    if ~ishghandle(params.plotting.verify_figure)
        %If it doesn't already exist, create it
        h = figure(params.plotting.verify_figure);
        h.NumberTitle = 'off';
        h.Name = 'Verify Parameters';
        
        %Set up basic initial features
        set(gcf, 'ToolBar', 'none');
        scrsz =  get(0,'ScreenSize'); 
        set(gcf, 'OuterPosition', [.1*scrsz(3) .1*scrsz(4) .8*scrsz(3) .8*scrsz(4)]);

        %%@ May be unnecessary
        %Set up tab group
        %tg = uitabgroup(h, 'TabLocation', 'left', 'Tag', 'calibration_tg');
    else
        h = figure(params.plotting.verify_figure);
    end
end