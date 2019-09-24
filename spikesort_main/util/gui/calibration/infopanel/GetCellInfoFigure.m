% Returns a handle to the cell info figure.
% If it doesn't exist, create it.

function h = GetCellInfoFigure
    global CBPdata params CBPInternals;

    if ishghandle(params.plotting.cell_info_figure)
        h = figure(params.plotting.cell_info_figure);
    else
        h = CreateCellInfoFigure;
    end
end
