% Resets the Params figure by deleting it and reloading it.

function ResetParamsFigure
    global params;
    
    if ishghandle(params.plotting.params_figure)
        clf(params.plotting.params_figure);
        CreateParamsFigure;
    else
        GetParamsFigure;
    end
end