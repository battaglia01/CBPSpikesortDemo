% -----------------
function ShowGroundTruthEval(spiketimes, f)
    global CBPdata params CBPInternals;

    true_sp = CBPdata.amplitude.true_sp;
    if isempty(true_sp), return; end
    slack = params.amplitude.spike_location_slack;

    % Evaluate CBP sorting
    [total_misses, total_false_positives] = ...
        EvaluateSortingLowLevel(spiketimes, true_sp, slack);

    % Display on fig
    %%@ if this is ever implemented, change the slow "findall" "tag" call below
    %%@ to a much faster cached pointer in the figure's appdata
    n = length(spiketimes);
    p = findall(GetCalibrationFigure,'Tag','amp_panel');

    for i = 1:length(true_sp)
        if isempty(true_sp{i}), continue; end
        subplot(n+1, n, i, 'Parent', p);
        xlabel(sprintf('misses: %d fps: %d', total_misses(i), total_false_positives(i)));
    end
end
