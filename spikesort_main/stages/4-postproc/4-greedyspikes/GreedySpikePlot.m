function GreedySpikePlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DisableCalibrationTab('Greedy Spike Plot');
        return;
    end

% -------------------------------------------------------------------------
% Check that we have ground truth
    if ~isfield(dataobj.ground_truth, 'true_sp')
        t=AddCalibrationTab('Greedy Spike Plot');
        cla('reset');
        axis off;
        uicontrol('Style','text',...
        'Parent',t,...
        'Units','normalized',...
        'Position',[0 0 1 1],...
        'HorizontalAlignment','center',...
        'FontSize',36,...
        'ForegroundColor','r',...
        'String',[10 10 'No Ground Truth!' 10 10 'Nothing to plot']);
        return;
    end
    
    %%@ GENERAL CLEAN UP
    est_times = dataobj.CBPinfo.spike_times;
    est_amps = dataobj.CBPinfo.spike_amps;
    true_times = dataobj.ground_truth.true_sp;
    location_slack = params.postproc.spike_location_slack;

    AddCalibrationTab('Greedy Spike Plot');
    
    % Actually some of the true_matches cells may be empty, but don't sweat this.
    ntruecells = length(true_times);
    colors = hsv(ntruecells);

    ax = [];
    cells_plotted = [];
    for i = 1:ntruecells
        %If this "true" spike has no times associated with it, continue
        if isempty(true_times{i})
            continue;
        end
        %else, add this to the list of cells plotted
        cells_plotted(end+1) = i;
        
        [ampthreshes cumfps cummisses cumfprate cummissrate] = ...
            CalcThreshROC(true_times{i}, est_times{i}, est_amps{i}, location_slack);

        % Plot FPs against threshold
        if isempty(ax)
            subplot(2,1,1);
            [ax hfps(i) hmiss(i)] = plotyy(ampthreshes, cumfps, ampthreshes, cummisses);
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
        axis([0 10 0 10]);
        xlabel('% miss rate');
        ylabel('% FP rate');
    end
    hold(ax(1), 'off'); % Will crash if nothing was plotted, but if nothing was plotted then assume something's already wrong
    hold(ax(2), 'off');

    % Legends
    fp_leg   = arrayfun(@(i) sprintf('FPs %i',    i), cells_plotted, 'UniformOutput', false);
    miss_leg = arrayfun(@(i) sprintf('Misses %i', i), cells_plotted, 'UniformOutput', false);
    legend(ax(1), [hfps(cells_plotted) hmiss(cells_plotted)], [fp_leg miss_leg]);


    % Autothreshold result
    ntrue = length(cell2mat(true_times));
    nauto = 0;
    for i = 1 : length(est_amps)
        %%@ - bug fixed below- mike
        %autothresh(i) = ComputeKDEThreshold(est_amps{i}, 32, [0.3 1.1], 5);
        autothresh(i) = ComputeKDEThreshold(est_amps{i}, params.amplitude);
        if i > length(true_times) || isempty(true_times{i}), continue; end
        nauto = nauto + sum(est_amps{i} > autothresh(i));
    end
    [automisses, autofps] = EvaluateSorting(est_times, est_amps, true_times, ...
        'threshold', autothresh, 'location_slack', location_slack);


    % Plot autothreshold
    subplot(2,1,2);
    hauto = plot(100 * sum(automisses(cells_plotted)) / ntrue, 100 * sum(autofps(cells_plotted)) / nauto, 'kx', 'MarkerSize', 15, 'LineWidth', 2);
    cell_leg = arrayfun(@(i) sprintf('Cell %i', i), cells_plotted, 'UniformOutput', false);
    legend([hroc(cells_plotted) hauto], [cell_leg 'Auto thresholds']);
    hold off;
end
