% GetParamsFigure returns a handle to the current params adjustment figure.
% If the figure doesn't already exist, it calls CreateParamsFigure and
% creates one. Also creates the TabGroup and Status Bar.

function h = GetParamsFigure
    global params dataobj cbpglobals;
    
    if ishghandle(params.plotting.params_figure)
        h = figure(params.plotting.params_figure);
    else
        h = CreateParamsFigure;
    end
end