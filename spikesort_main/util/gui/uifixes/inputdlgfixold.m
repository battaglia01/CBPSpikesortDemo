% This is a fixed version of inputdlg.m that uses the correct font size.

function out = inputdlgfix(varargin)
    % the secondparameter is always the title, which is also the tag name.
    t = timer;
    t.StartDelay = .2;
    t.TimerFcn = @(~,~) changefont;
    t.StopFcn = @(this,~) delete(this);
    t.start()
    out = inputdlg(varargin{:});
end

function changefont
    factorysize = get(0,'FactoryUicontrolFontSize');
    defaultsize = get(0,'DefaultUicontrolFontSize');
    fig = getinputdlgfig;
    disp('lol');
    c = findall(fig);
    % now set the font size
    for n=2:length(c)
        try
            set(c(n), 'FontSize', defaultsize);
        end
    end
    % now resize the figure
    th = findall(groot, 'Tag', 'Quest');
    deltaWidth = sum(th.Extent([1,3]))-fig.Position(3) + th.Extent(1);
    deltaHeight = sum(th.Extent([2,4]))-fig.Position(4) + 10;
    fig.Position([3,4]) = fig.Position([3,4]) + [deltaWidth, deltaHeight];
end

function out = getinputdlgfig
    out = findall(groot, 'Tag', 'Edit');
    out = get(out, 'Parent');
end