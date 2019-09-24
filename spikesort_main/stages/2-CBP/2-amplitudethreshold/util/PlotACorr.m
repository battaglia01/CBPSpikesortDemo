% -----------------
function PlotACorr(spiketimes, totalcells, cell)
    global CBPInternals;
    truecell = CBPInternals.cells_to_plot(cell);

    subplot(totalcells+1, totalcells, sub2ind([totalcells totalcells+1], cell, 2));

    ProcessACorr(spiketimes{truecell}, 0, 0.03);
    title(sprintf('Autocorr, cell %d', truecell));
    if (cell==1)
        xlabel('Time (ms)');
    end
end
