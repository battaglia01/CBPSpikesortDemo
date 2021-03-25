function PlotGroundTruthAssignmentMatrix(tp_mtx, fp_mtx, miss_mtx, ...
                                         num_true, num_est, ...
                                         total_tp, total_fp, total_misses, ...
                                         total_spikes, total_spikes_true, ...
                                         best_ordering, balanced, spike_name)
	global params CBPData
    
    % set up some reusable locals
    all_err_mtx = fp_mtx + miss_mtx;
    font_size = 12; % font size for text
    get_best_ordering = @(x) find(best_ordering(:, x));
    
    % If our matrix is "balanced," some of the est. waveforms are simply
    % "unassigned," and if it's "unbalanced," the est. waveforms are all
    % assigned.
    if params.ground_truth.balanced
        % if it's balanced:
        % - the the rows have max size equal to the number of estimated
        %   plus possibly one for "unassigned"
        % - the the cols have max size equal to the number of true
        %   plus possibly one for "unassigned"
        num_rows = min(num_est+1, size(miss_mtx, 1));
        num_cols = min(num_true+1, size(miss_mtx, 2));
    else
        % if it's unbalanced:
        % - the the rows have size equal to the number of estimated
        % - the the cols have max size equal to the number of true
        %   plus possibly one for "unassigned"
        num_rows = min(num_est+1, size(miss_mtx, 1));
        num_cols = num_true;
    end
    
    % clear axes first
    cla;
    drawnow;
    pause(0.01);

    % plot original error matrix
    imagesc(all_err_mtx(1:num_rows, 1:num_cols));

    % now set axes, colormap, etc
    invgray = 1 - gray;
    colormap(gca, invgray); % lighter color = less errors
    axis equal;
    axis tight;
    set(gca, 'FontSize', font_size);
    set(gca, 'TickLength', [0 0]);
    set(gca, 'YTick', 1:num_rows, 'XTick', 1:num_cols);
    if num_rows > num_est
        set(gca, 'YTickLabels', {1:num_est, "unassigned"});
    end
    if num_true == 0
        set(gca, 'XTickLabels', {"unassigned"});
    elseif num_cols > num_true
        set(gca, 'XTickLabels', {1:num_true, "unassigned"});
    end


    tp_str = sprintf("%d/%d (%.2f%%)", total_tp, ...
                     total_spikes_true, ...
                     100*total_tp/total_spikes_true);
    miss_str = sprintf("%d/%d (%.2f%%)", total_misses, ...
                       total_spikes_true, ...
                       100*total_misses/total_spikes_true);
    fp_str = sprintf("%d/%d (%.2f%%)", total_fp, ...
                     total_spikes, ...
                     100*total_fp/total_spikes);
    title(spike_name + " error matrix results" + newline + ...
          "\color[rgb]{0.0,0.5,1.0}True Positives: " + tp_str + " " + ...
          "\color[rgb]{1.0,0.0,0.0}False Negatives: " + miss_str + " " + ...
          "\color[rgb]{1.0,0.5,0.0}False Positives: " + fp_str + newline + ...
          "\color[rgb]{0.0,0.0,0.0}" + spike_name + " spike times used to " + ...
          "determine \color[rgb]{0.3,0.8,1.0}assignments");
    xlabel('True Waveform ID');
    ylabel('Estimated Waveform ID');

    % add colorbar
    c = colorbar("Direction", "reverse");
    c.Label.String = "Total Errors (False Negatives + False Positives)";

    % now plot the indicators highlighting the chosen assignments
    for n=1:size(best_ordering, 2)
        assignments = min(get_best_ordering(n), num_rows);
        for m=1:length(assignments)
            n = min(num_cols, n);
            rectangle('Position', [n-0.125 assignments(m)-0.125 0.25 0.25], ...
                      'Curvature', 1, ...
                      'FaceColor', [0.3 0.8 1]);
        end
    end

    % add text
    % first do a quick test to get the width. render off the screen
    max_mtx = max(miss_mtx, fp_mtx);
    max_num = max(max_mtx(:));
    text_size = 1/num_rows;
    tmp = text(10 * num_cols, 10 * num_rows, num2str(max_num), ...
               'HorizontalAlignment', 'left', ...
               'VerticalAlignment', 'cap', ...
               'Color', [1.0 0.0 0.0], ...
               'FontUnits', 'normalized', ...
               'FontWeight', 'bold', ...
               'FontSize', 1/num_rows);
    set(tmp, 'Units', 'normalized');

    % get current true font size
    largest_dim = get(tmp, 'Extent');

    % the largest dimension is either the width, or the height times two
    % (since this takes up half of a box)
    largest_dim = max([largest_dim(3) largest_dim(4)*2]);

    % multiply by 0.9 to get some padding
    text_size = 0.9 * text_size * text_size / largest_dim;
    delete(tmp);

    for r=1:num_rows
        for c=1:num_cols
            t = text(c - 0.45, r - 0.45, num2str(miss_mtx(r, c)), ...
                     'HorizontalAlignment', 'left', ...
                     'VerticalAlignment', 'cap', ...
                     'Color', [1.0 0.0 0.0], ...
                     'FontUnits', 'normalized', ...
                     'FontWeight', 'bold', ...
                     'FontSize', text_size);
            t = text(c + 0.45, r + 0.45, num2str(fp_mtx(r, c)), ...
                     'HorizontalAlignment', 'right', ...
                     'VerticalAlignment', 'bottom', ...
                     'Color', [1.0 0.5 0.0], ...
                     'FontUnits', 'normalized', ...
                     'FontWeight', 'bold', ...
                     'FontSize', text_size);
        end
    end
