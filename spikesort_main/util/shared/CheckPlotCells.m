% Simple helper function that checks if num_cells is 0 and returns an
% error if it is.
% This was made its own function because multiple plots were doing this
% same check and throwing the same error, so it's easier to have a shared
% function for easy changes

function CheckPlotCells(num_cells)
    if num_cells == 0
        error("No valid cell indices to plot!\n" + ...
              "This is likely because the cell indices CBPInternals.cells_to_plot are invalid.\n" + ...
              "Change CBPInternals.cells_to_plot and try again!", "");
    end
end