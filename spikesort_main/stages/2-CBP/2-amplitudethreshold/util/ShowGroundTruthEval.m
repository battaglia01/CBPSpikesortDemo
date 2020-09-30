% -----------------
%%@ NOTE: This is not currently implemented, but the framework is below for when
%%@ it eventually is implemented.
function ShowGroundTruthEval(spiketimes, f)
    global CBPdata params CBPInternals;

    spike_time_array_processed = CBPdata.amplitude.spike_time_array_processed;
    if isempty(spike_time_array_processed), return; end
    slack = params.amplitude.spike_location_slack;

    % Evaluate CBP sorting
    [total_misses, total_false_positives] = ...
        EvaluateSortingLowLevel(spiketimes, spike_time_array_processed, slack);

    % Display on fig
    n = length(spiketimes);
    p = LookupTag('amp_panel');

    for i = 1:length(spike_time_array_processed)
        if isempty(spike_time_array_processed{i}), continue; end
        subplot(n+1, n, i, 'Parent', p);
        xlabel(sprintf('misses: %d fps: %d', total_misses(i), total_false_positives(i)));
    end
end
