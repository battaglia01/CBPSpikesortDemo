% Note - plotting is much faster if mex greedymatchtimes.c is compiled
%*** TODO - show chosen threshold in top plot
%*** TODO - also show log # spikes found?


function GreedySpikePlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Greedy Spike Plot');
        return;
    end

% -------------------------------------------------------------------------
% Check that we have ground truth
    if ~isfield(CBPdata.ground_truth, 'spike_time_array_processed') || ...
       length(CBPdata.ground_truth.spike_time_array_processed) == 0
        t = CreateCalibrationTab('Greedy Spike Plot', 'GreedySpike');
        cla('reset');
        axis off;
        uicontrol('Style', 'text', ...
                  'Parent', t, ...
                  'Units', 'normalized', ...
                  'Position', [0 0 1 1], ...
                  'HorizontalAlignment', 'center', ...
                  'FontSize', 36, ...
                  'ForegroundColor', 'r', ...
                  'String', sprintf('\n\nNo Ground Truth!\n\nNothing to plot'));
        return;
    end

% -------------------------------------------------------------------------
% Create Main Tab
    %%@ GENERAL CLEAN UP
    %%@ Mike's note - this originally referenced the pre-refinement,
    %%@ pre-thresholded CBP raw spike times - left for reference but
    %%@ updated to waveform refinement
%     est_times = CBPdata.CBP.spike_time_array;
%     est_amps = CBPdata.CBP.spike_amps;
    est_times = CBPdata.waveform_refinement.spike_time_array_thresholded;
    num_est = length(est_times);
    est_amps = CBPdata.waveform_refinement.spike_amps_thresholded;
    best_ordering_cbp = CBPdata.ground_truth.best_ordering_cbp;
    true_times = CBPdata.ground_truth.spike_time_array_processed;
    location_slack = params.amplitude.spike_location_slack;

    CreateCalibrationTab('Greedy Spike Plot', 'GreedySpike');

    % Actually some of the true_matches cells may be empty, but don't sweat
    % this.
    ntruecells = length(true_times);
    colors = hsv(ntruecells);

    ax = [];
    cells_plotted = [];
    for i = 1:ntruecells
        % If this "true" spike has no times associated with it, continue
        if isempty(true_times{i})
            continue;
        end
        
        % Now we need to determine the correct "est_times" to choose
        est_indices = find(best_ordering_cbp(:, i));
        est_indices = est_indices(est_indices <= num_est);
        % If this is empty, just skip it
        if isempty(est_indices)
            continue;
        end
        
        % If we got this far, add this to the list of cells plotted
        cells_plotted(end+1) = i;
        
        cur_est_mtx = [vertcat(est_times{est_indices}) vertcat(est_amps{est_indices})];
        cur_est_mtx = sortrows(cur_est_mtx, 1);
        cur_est_times = cur_est_mtx(:, 1);
        cur_est_amps = cur_est_mtx(:, 2);

        [ampthreshes cumfps cummisses cumfprate cummissrate] = ...
            CalcThreshROC(true_times{i}, cur_est_times, cur_est_amps, ...
                          location_slack);

        % Plot FPs against threshold
        if isempty(ax)
            subplot(2,1,1);
            [ax hfps(i) hmiss(i)] = plotyy(ampthreshes, cumfps, ampthreshes, ...
                                           cummisses);
            hold(ax(1), 'on');
            hold(ax(2), 'on');
            set(ax, 'YColor', 'k');
            xlabel threshold
            ylabel(ax(1), '# FPs');
            ylabel(ax(2), '# Misses');
        else
            hfps(i)  = plot(ax(1), ampthreshes, cumfps);
            hmiss(i) = plot(ax(2), ampthreshes, cummisses);
        end
        set(hfps(i),  'Color', colors(i,:));
        set(hmiss(i), 'Color', colors(i,:), 'LineStyle', '--');

        % Plot Misses versus FPs as threhold changes
        subplot(2,1,2);
        hroc(i) = plot(cummissrate .* 100, cumfprate .* 100, '.');
        hold on
        set(hroc(i), 'Color', colors(i,:));
        axis([-5 105 -5 105]);
        xlabel('% miss rate');
        ylabel('% FP rate');
    end
    % Below will crash if nothing was plotted, but if nothing was plotted then
    % assume something's already wrong
    hold(ax(1), 'off');
    hold(ax(2), 'off');

    % Legends
    fp_leg   = arrayfun(@(i) sprintf('FPs %i',    i), cells_plotted, ...
                        'UniformOutput', false);
    miss_leg = arrayfun(@(i) sprintf('Misses %i', i), cells_plotted, ...
                        'UniformOutput', false);
    legend(ax(1), [hfps(cells_plotted) hmiss(cells_plotted)], [fp_leg miss_leg]);


    % Autothreshold result
    ntrue = length(cell2mat(true_times));
    nauto = 0;

    num_points = params.amplitude.kdepoints;
    range = params.amplitude.kderange;
    peak_width = params.amplitude.kdewidth;

    for i = 1 : length(est_amps)
        %%@ - bug fixed below- mike
        %autothresh(i) = ComputeKDEThreshold(est_amps{i}, 32, [0.3 1.1], 5);
        autothresh(i) = ComputeKDEThreshold(est_amps{i}, num_points, range, ...
                                            peak_width);
        if i > length(true_times) || isempty(true_times{i}), continue; end
        nauto = nauto + sum(est_amps{i} > autothresh(i));
    end
    [automisses, autofps, autotps, ~, ~, ~, ~] = ...
        EvaluateSorting(est_times, est_amps, true_times, ...
                        best_ordering_cbp, 'threshold', autothresh, ...
        'location_slack', location_slack);


    % Plot autothreshold
    subplot(2,1,2);
    hauto = plot(100 * sum(automisses(cells_plotted)) / ntrue, ...
                 100 * sum(autofps(cells_plotted))/nauto, ...
                 'kx', 'MarkerSize', 15, 'LineWidth', 2);
    cell_leg = arrayfun(@(i) sprintf('Cell %i', i), cells_plotted, ...
                        'UniformOutput', false);
    legend([hroc(cells_plotted) hauto], [cell_leg 'Auto thresholds']);
    hold off;
end
