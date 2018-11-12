% -----------------
function plotXCorr(spiketimes, i, j)
    if j < i
        tmp = i;
        i = j;
        j = tmp;
    end
    n = length(spiketimes);
    p = findall(GetCalibrationFigure,'Tag','amp_panel');

    subplot(n+1, n, sub2ind([n n+1], j, i+2));
    psthxcorr(spiketimes{i}, spiketimes{j});
    title(sprintf('Xcorr, cells %d, %d', i, j));
    if (j == i+1)       %%@Mike's change - plot at bottom of each column
        xlabel('Time (ms)');
    end
end
