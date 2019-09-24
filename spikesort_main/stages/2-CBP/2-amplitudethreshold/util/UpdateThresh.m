% Update thresholds. First parameter is the cluster indices to update, second is
% the figure
function UpdateThresh(inds, f)
    global CBPdata params CBPInternals;

    % First thing to do is check if anything has changed at all.
    % If not, return
    goodinds = [];
    for c = inds
        newthresh = getappdata(f, ['imline_pos_' num2str(c)]);
        oldthresh = CBPdata.amplitude.amp_thresholds;
        oldthresh = oldthresh(c);
        if newthresh ~= oldthresh
            goodinds = [goodinds c];
        end
    end
    if isempty(goodinds)
        return;
    end

    % If we got this far, we have some good inds.
    % So, disable the status bar and clear stale tabs
    SetCalibrationLoading(true);
    ampstage = GetStageFromName('AmplitudeThreshold');
    ClearStaleTabs(ampstage.next);

    % Now, loop through all good inds. if threshold hasn't changed, continue
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

    for c = goodinds
        % c is the "true" index, n is the subplot index
        n = find(plot_cells == c);

        % get new threshold
        newthresh = getappdata(f, ['imline_pos_' num2str(c)]);

        % Calculate new threshed sts
        CBPdata.amplitude.thresh_spike_times_ms{c} = ...
            CBPdata.CBP.spike_times_ms{c}(CBPdata.CBP.spike_amps{c} > newthresh);

        % Plot autocorr first, then Xcorr with each other plot

        PlotACorr(CBPdata.amplitude.thresh_spike_times_ms, num_cells, n);
        for m = 1:num_cells
            if m == n
                continue;
            end
            PlotXCorr(CBPdata.amplitude.thresh_spike_times_ms, num_cells, n, m);
        end

        % Now save new thresh
        CBPdata.amplitude.amp_thresholds(c) = newthresh;
    end

    % If Ground Truth is defined, plot this, otherwise do nothing
    ShowGroundTruthEval(CBPdata.amplitude.thresh_spike_times_ms, f);

    % Done! Reset the status bar to AmplitudeThreshold
    SetCalibrationLoading(false);
end
