% -----------------
function plotACorr(spiketimes, i)
    n = length(spiketimes);
    p = findall(GetCalibrationFigure,'Tag','amp_panel');

    subplot(n+1, n, sub2ind([n n+1], i, 2));
    psthacorr(spiketimes{i});
    title(sprintf('Autocorr, cell %d', i));
    if (i==1)
        xlabel('Time (ms)');
    end
end
