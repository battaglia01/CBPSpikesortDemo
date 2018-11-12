% -----------------
function ShowGroundTruthEval(spiketimes, f)
    true_sp = getappdata(f, 'true_sp');
    if isempty(true_sp), return; end
    slack = getappdata(f, 'location_slack');

    % Evaluate CBP sorting
    [total_misses, total_false_positives] = ...
        evaluate_sorting(spiketimes, true_sp, slack);

    % Display on fig
    n = length(spiketimes);
    p = findall(GetCalibrationFigure,'Tag','amp_panel');

    for i = 1:length(true_sp)
        if isempty(true_sp{i}), continue; end
        subplot(n+1, n, i, 'Parent', p);
        xlabel(sprintf('misses: %d fps: %d', total_misses(i), total_false_positives(i)));
    end
end
