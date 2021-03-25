% -----------------
function PlotXCorr(spiketimes, totalcells, cell1, cell2)
    global CBPInternals;

    % make sure cell1 < cell2
    if cell2 < cell1
        tmp = cell1;
        cell1 = cell2;
        cell2 = tmp;
    end
    
    % get true indices from params
    truecell1 = CBPInternals.cells_to_plot(cell1);
    truecell2 = CBPInternals.cells_to_plot(cell2);

    subplot(totalcells+1, totalcells, sub2ind([totalcells totalcells+1], cell2, cell1+2));
    ProcessXCorr(spiketimes{truecell1}, spiketimes{truecell2}, -0.05, 0.05);   % do from -50ms to 50ms
    title(sprintf('Xcorr, cells %d, %d', truecell1, truecell2));
    
    % at the bottom of each column, plot the "Time" xlabel
    if (cell2 == cell1+1)
        xlabel('Time (ms)');
    end
end
