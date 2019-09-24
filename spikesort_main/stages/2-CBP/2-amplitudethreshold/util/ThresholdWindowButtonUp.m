function ThresholdWindowButtonUp(varargin)
global CBPdata params CBPInternals;
    % Timer makes drawing easier
    t = timer;
    t.StartDelay = .2;

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

    t.TimerFcn = @(~,~) UpdateThresh(plot_cells, GetCalibrationFigure);
    start(t);
end
