function GroundTruthPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Clustering Error Matrix');
        DeleteCalibrationTab('CBP Error Matrix');
        DeleteCalibrationTab('True Waveform Comparison');
%         DeleteCalibrationTab('No Ground Truth!')
        return;
    end
    

%% -------------------------------------------------------------------------
% Set up basics

    best_ordering_cl = CBPdata.groundtruth.best_ordering_cl;
    best_ordering_cbp = CBPdata.groundtruth.best_ordering_cbp;
    % these are the false negative/false positive/combined error matrices,
    % which have rows as estimated waveform ID #'s and cols as true
    % waveform ID #'s

    %%@ note: in both situations we use the "best_ordering" assignments
    %%above
    miss_mtx_cl = CBPdata.groundtruth.miss_mtx_cl;
    fp_mtx_cl = CBPdata.groundtruth.fp_mtx_cl;
    all_err_mtx_cl = CBPdata.groundtruth.all_err_mtx_cl;

    miss_mtx_cbp = CBPdata.groundtruth.miss_mtx_cbp;
    fp_mtx_cbp = CBPdata.groundtruth.fp_mtx_cbp;
    all_err_mtx_cbp = CBPdata.groundtruth.all_err_mtx_cbp;

    % these are the num estimated/true waveforms, as well as rows/cols of
    % the matrix (may be expanded to add "dummy" unassigned values)
    num_true = length(unique(CBPdata.groundtruth.true_spike_class));   % number of true waveforms, without extra columns
    num_est_cl = params.clustering.num_waveforms;                      % number of estimated clustering waveforms, without extra rows
    num_est_cbp = CBPdata.waveformrefinement.num_waveforms;            % number of estimated CBP waveforms, without extra rows
    num_rows_cl = min(num_est_cl+1, size(miss_mtx_cl, 1));
    num_rows_cbp = min(num_est_cbp+1, size(miss_mtx_cbp, 1));
    num_cols_cl = min(num_true+1, size(miss_mtx_cl, 2));
    num_cols_cbp = min(num_true+1, size(miss_mtx_cbp, 2));

    % these are the total number of false negatives/positives, and spikes
    total_misses_cl = 0;
    total_fp_cl = 0;
    total_misses_cbp = 0;
    total_fp_cbp = 0;
    total_spikes_true = length(CBPdata.groundtruth.true_spike_times);
    total_spikes_cl = length(cell2mat(CBPdata.clustering.spike_time_array_cl));
    total_spikes_cbp = length(cell2mat(CBPdata.waveformrefinement.spike_time_array_thresholded));

    for n=1:num_cols_cl
        total_misses_cl = total_misses_cl + ...
            miss_mtx_cl(best_ordering_cl(n), n);
        total_fp_cl = total_fp_cl + ...
            fp_mtx_cl(best_ordering_cl(n), n);
    end

    for n=1:num_cols_cbp
        total_misses_cbp = total_misses_cbp + ...
            miss_mtx_cbp(best_ordering_cbp(n), n);
        total_fp_cbp = total_fp_cbp + ...
            fp_mtx_cbp(best_ordering_cbp(n), n);
    end

    % font size for text
    font_size = 12;
    
    if CBPdata.groundtruth.blank_ground_truth
        ground_truth_note_string = ...
            "NOTE: Ground truth not present!"
    else
        ground_truth_note_string = ...
            "";
    end
    ground_truth_note_params = ...
        {"Style", "Text", ...
         "Units", "Normalized", ...
         "Position", [0.6 0 0.4 0.05], ...
         "FontUnits", "Normalized", ...
         "FontSize", 0.75, ...
         "ForegroundColor", [1.0 0.0 0.0], ...
         "HorizontalAlignment", "right", ...
         "String", ground_truth_note_string};

%% -------------------------------------------------------------------------
% Plotting false negatives and positives for clustering
    maintab = CreateCalibrationTab('Clustering Error Matrix', 'GroundTruth');

    % clear axes first
    cla;
    drawnow;
    pause(0.01);

    % plot original error matrix
    imagesc(all_err_mtx_cl(1:num_rows_cl, 1:num_cols_cl));

    % now set axes, colormap, labels etc
    invgray = 1 - gray;
    colormap(gca, invgray); % lighter color = less errors
    axis equal;
    axis tight;
    set(gca, 'FontSize', font_size);
    set(gca, 'TickLength', [0 0]);
    set(gca, 'YTick', 1:num_rows_cl, 'XTick', 1:num_cols_cl);
    if num_rows_cl > num_est_cl
        set(gca, 'YTickLabels', {1:num_est_cl, "unassigned"});
    end
    if num_true == 0
        set(gca, 'XTickLabels', {"unassigned"});
    elseif num_cols_cl > num_true
        set(gca, 'XTickLabels', {1:num_true, "unassigned"});
    end

    
    miss_str = sprintf("%d/%d (%.2f%%)", total_misses_cl, total_spikes_true, ...
                                                          100*total_misses_cl/total_spikes_true);
    fp_str = sprintf("%d/%d (%.2f%%)", total_fp_cl, total_spikes_cl, ...
                                                    100*total_fp_cl/total_spikes_cl);
    title("Clustering error matrix results" + newline + ...
          "\color[rgb]{1.0,0.0,0.0}False Negatives: " + miss_str + " " + ...
          "\color[rgb]{1.0,0.5,0.0}False Positives: " + fp_str + newline + ...
          "\color[rgb]{0.0,0.0,0.0}Clustering spike times used to " + ...
          "determine \color[rgb]{0.3,0.8,1.0}assignments");
    xlabel('True Waveform ID');
    ylabel('Estimated Waveform ID');

    % add colorbar
    c = colorbar("Direction", "reverse");
    c.Label.String = "Total Errors (False Negatives + False Positives)";

    % now plot rectangles highlighting the chosen assignments
    for n=1:length(best_ordering_cl)
        assignment = min(best_ordering_cl(n), num_rows_cl);
        n = min(num_cols_cl, n);
        rectangle('Position', [n-0.125 assignment-0.125 0.25 0.25], ...
                  'Curvature', 1, ...
                  'FaceColor', [0.3 0.8 1])
    end

    % add text
    % first do a quick test to get the width. render off the screen
    max_mtx_cl = max(miss_mtx_cl, fp_mtx_cl);
    max_num_cl = max(max_mtx_cl(:));
    text_size = 1/num_rows_cl;
    tmp = text(10 * num_cols_cl, 10 * num_rows_cl, num2str(max_num_cl), ...
               'HorizontalAlignment', 'left', ...
               'VerticalAlignment', 'cap', ...
               'Color', [1.0 0.0 0.0], ...
               'FontUnits', 'normalized', ...
               'FontWeight', 'bold', ...
               'FontSize', 1/num_rows_cl);
    set(tmp, 'Units', 'normalized');

    % get current true font size
    largest_dim = get(tmp, 'Extent');

    % the largest dimension is either the width, or the height times two
    % (since this takes up half of a box)
    largest_dim = max([largest_dim(3) largest_dim(4)*2]);

    % multiply by 0.9 to get some padding
    text_size = 0.9 * text_size * text_size / largest_dim;
    delete(tmp);

    for r=1:num_rows_cl
        for c=1:num_cols_cl
            t = text(c - 0.45, r - 0.45, num2str(miss_mtx_cl(r, c)), ...
                     'HorizontalAlignment', 'left', ...
                     'VerticalAlignment', 'cap', ...
                     'Color', [1.0 0.0 0.0], ...
                     'FontUnits', 'normalized', ...
                     'FontWeight', 'bold', ...
                     'FontSize', text_size);
            t = text(c + 0.45, r + 0.45, num2str(fp_mtx_cl(r, c)), ...
                     'HorizontalAlignment', 'right', ...
                     'VerticalAlignment', 'bottom', ...
                     'Color', [1.0 0.5 0.0], ...
                     'FontUnits', 'normalized', ...
                     'FontWeight', 'bold', ...
                     'FontSize', text_size);
        end
    end

    changebutton = uicontrol(maintab, 'Tag', 'groundtruth_permutation', ...
                           'Style', 'pushbutton', ...
                           'FontSize', 14, ...
                           'String', 'Change Permutation...', ...
                           'Units', 'normalized', ...
                           'Position', [0 0 0.25 0.05], ...
                           'Callback', @changeCallback);
	ground_truth_note = uicontrol(maintab, ground_truth_note_params{:});

%% -------------------------------------------------------------------------
% Plotting false negatives and positives for CBP
    maintab = CreateCalibrationTab('CBP Error Matrix', 'GroundTruth');

    % clear axes first
    cla;
    drawnow;
    pause(0.01);

    % plot original error matrix
    imagesc(all_err_mtx_cbp(1:num_rows_cbp, 1:num_cols_cbp));

    % now set axes, colormap, etc
    invgray = 1 - gray;
    colormap(gca, invgray); % lighter color = less errors
    axis equal;
    axis tight;
    set(gca, 'FontSize', font_size);
    set(gca, 'TickLength', [0 0]);
    set(gca, 'YTick', 1:num_rows_cbp, 'XTick', 1:num_cols_cbp);
    if num_rows_cbp > num_est_cbp
        set(gca, 'YTickLabels', {1:num_est_cbp, "unassigned"});
    end
    if num_true == 0
        set(gca, 'XTickLabels', {"unassigned"});
    elseif num_cols_cbp > num_true
        set(gca, 'XTickLabels', {1:num_true, "unassigned"});
    end


    miss_str = sprintf("%d/%d (%.2f%%)", total_misses_cbp, total_spikes_true, ...
                                         100*total_misses_cbp/total_spikes_true);
    fp_str = sprintf("%d/%d (%.2f%%)", total_fp_cbp, total_spikes_cbp, ...
                                                     100*total_fp_cbp/total_spikes_cbp);
    title("CBP error matrix results" + newline + ...
          "\color[rgb]{1.0,0.0,0.0}False Negatives: " + miss_str + " " + ...
          "\color[rgb]{1.0,0.5,0.0}False Positives: " + fp_str + newline + ...
          "\color[rgb]{0.0,0.0,0.0}CBP spike times used to " + ...
          "determine \color[rgb]{0.3,0.8,1.0}assignments");
    xlabel('True Waveform ID');
    ylabel('Estimated Waveform ID');

    % add colorbar
    c = colorbar("Direction", "reverse");
    c.Label.String = "Total Errors (False Negatives + False Positives)";

    % now plot rectangles highlighting the chosen assignments
    for n=1:length(best_ordering_cbp)
        assignment = min(best_ordering_cbp(n), num_rows_cbp);
        n = min(num_cols_cbp, n);
        rectangle('Position', [n-0.125 assignment-0.125 0.25 0.25], ...
                  'Curvature', 1, ...
                  'FaceColor', [0.3 0.8 1])
    end

    % add text
    % first do a quick test to get the width. render off the screen
    max_mtx_cbp = max(miss_mtx_cbp, fp_mtx_cbp);
    max_num_cbp = max(max_mtx_cbp(:));
    text_size = 1/num_rows_cbp;
    tmp = text(10 * num_cols_cbp, 10 * num_rows_cbp, num2str(max_num_cbp), ...
               'HorizontalAlignment', 'left', ...
               'VerticalAlignment', 'cap', ...
               'Color', [1.0 0.0 0.0], ...
               'FontUnits', 'normalized', ...
               'FontWeight', 'bold', ...
               'FontSize', 1/num_rows_cbp);
    set(tmp, 'Units', 'normalized');

    % get current true font size
    largest_dim = get(tmp, 'Extent');

    % the largest dimension is either the width, or the height times two
    % (since this takes up half of a box)
    largest_dim = max([largest_dim(3) largest_dim(4)*2]);

    % multiply by 0.9 to get some padding
    text_size = 0.9 * text_size * text_size / largest_dim;
    delete(tmp);

    for r=1:num_rows_cbp
        for c=1:num_cols_cbp
            t = text(c - 0.45, r - 0.45, num2str(miss_mtx_cbp(r, c)), ...
                     'HorizontalAlignment', 'left', ...
                     'VerticalAlignment', 'cap', ...
                     'Color', [1.0 0.0 0.0], ...
                     'FontUnits', 'normalized', ...
                     'FontWeight', 'bold', ...
                     'FontSize', text_size);
            t = text(c + 0.45, r + 0.45, num2str(fp_mtx_cbp(r, c)), ...
                     'HorizontalAlignment', 'right', ...
                     'VerticalAlignment', 'bottom', ...
                     'Color', [1.0 0.5 0.0], ...
                     'FontUnits', 'normalized', ...
                     'FontWeight', 'bold', ...
                     'FontSize', text_size);
        end
    end

    changebutton = uicontrol(maintab, 'Tag', 'groundtruth_permutation', ...
                             'Style', 'pushbutton', ...
                             'FontSize', 14, ...
                             'String', 'Change Permutation...', ...
                             'Units', 'normalized', ...
                             'Position', [0 0 0.25 0.05], ...
                             'Callback', @changeCallback);
	ground_truth_note = uicontrol(maintab, ground_truth_note_params{:});
                         
%% -------------------------------------------------------------------------
% Comparing true waveforms for CBP and Clustering
    if isfield(CBPdata.groundtruth, 'true_spike_waveforms')
        maintab = CreateCalibrationTab('True Waveform Comparison', ...
                                       'GroundTruth');

        dt = CBPdata.whitening.dt;
        nchan = size(CBPdata.whitening.data,1);

        true_num_plot_cells = CBPdata.waveformrefinement.num_waveforms;
        plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_plot_cells);
        num_plot_cells = length(plot_cells);
        CheckPlotCells(num_plot_cells);

        nc = ceil(sqrt(num_plot_cells));
        nr = ceil(num_plot_cells / nc);

        t_axis = (1:size(CBPdata.waveformrefinement.final_waveforms{1},1))*dt*1000;

        % first, take the ground truth waveforms and filter/whiten them
        % using the same settings as the original signal
        refiltered_trues = ...
            RefilterAndWhitenWaveforms(...
                CBPdata.groundtruth.true_spike_waveforms, ...
                CBPdata.filtering.coeffs, ...
                CBPdata.whitening.old_acfs, ...
                CBPdata.whitening.old_cov, ...
                params.whitening.reg_const);
            
        % first, get axis limits - makes plotting faster
        max_xlim = [min(t_axis) max(t_axis)];
        max_ylim = [Inf -Inf];
        for n = 1:num_plot_cells
            c = plot_cells(n);

            % make sure this is really a true cell - sometimes the
            % assignment mechanism can assign "fake" ground truth numbers
            % to estimated waveforms to represent "unassigned" waveforms
            if ~ismember(c, 1:num_true)
                continue;
            end

            % get current true and estimated waveform
            cur_true = refiltered_trues{c};
            if best_ordering_cl(c) <= length(CBPdata.clustering.init_waveforms)
                cur_est_cl = ...
                    CBPdata.clustering.init_waveforms{best_ordering_cl(c)};
            else
                cur_est_cl = ...
                    zeros(size(CBPdata.clustering.init_waveforms{1}));
            end
            
            if best_ordering_cbp(c) <= length(CBPdata.waveformrefinement.final_waveforms)
                cur_est_cbp = ...
                    CBPdata.waveformrefinement.final_waveforms{best_ordering_cbp(c)};
            else
                cur_est_cbp = ...
                    zeros(size(CBPdata.waveformrefinement.final_waveforms{1}));
            end
            

            % normalize each waveform by the frobenius norm for better
            % comparisons
            %%@ note - if one of the waveforms has somehow converged on the
            %%@ zero vector, this will be NaN, so this replaces it with 0
            cur_true = fillmissing(cur_true ./ norm(cur_true, 'fro'), 'constant', 0);
            cur_est_cbp = fillmissing(cur_est_cbp ./ norm(cur_est_cbp, 'fro'), 'constant', 0);
            cur_est_cl = fillmissing(cur_est_cl ./ norm(cur_est_cl, 'fro'), 'constant', 0);
            
            tmp_ylim = [min([cur_true(:);cur_est_cl(:);cur_est_cbp(:)]) max([cur_true(:);cur_est_cl(:);cur_est_cbp(:)])];
            max_ylim(1) = min(tmp_ylim(1), max_ylim(1));
            max_ylim(2) = max(tmp_ylim(2), max_ylim(2));
        end
        
        % now plot the cells
        skipped = [];
        for n=1:num_plot_cells
            c = plot_cells(n);

            % make sure this is really a true cell - sometimes the
            % assignment mechanism can assign "fake" ground truth numbers
            % to estimated waveforms to represent "unassigned" waveforms
            if ~ismember(c, 1:num_true)
                skipped(end+1) = n;
                continue;
            end
            subplot(nr, nc, n);
            cla;

            % get current true and estimated waveform
            % get current true and estimated waveform
            cur_true = refiltered_trues{c};
            if best_ordering_cl(c) <= length(CBPdata.clustering.init_waveforms)
                cur_est_cl = ...
                    CBPdata.clustering.init_waveforms{best_ordering_cl(c)};
            else
                cur_est_cl = ...
                    zeros(size(CBPdata.clustering.init_waveforms{1}));
            end
            
            if best_ordering_cbp(c) <= length(CBPdata.waveformrefinement.final_waveforms)
                cur_est_cbp = ...
                    CBPdata.waveformrefinement.final_waveforms{best_ordering_cbp(c)};
            else
                cur_est_cbp = ...
                    zeros(size(CBPdata.waveformrefinement.final_waveforms{1}));
            end

            % normalize each waveform by the frobenius norm for better
            % comparisons
            %%@ note - if one of the waveforms has somehow converged on the
            %%@ zero vector, this will be NaN, so this replaces it with 0
            cur_true = fillmissing(cur_true ./ norm(cur_true, 'fro'), 'constant', 0);
            cur_est_cbp = fillmissing(cur_est_cbp ./ norm(cur_est_cbp, 'fro'), 'constant', 0);
            cur_est_cl = fillmissing(cur_est_cl ./ norm(cur_est_cl, 'fro'), 'constant', 0);

            % get maximum time-offset between the two (clustering)
            offset_cl = 0;
            for m=1:nchan
                [cur_xcorr cur_lags] = xcorr(cur_true(:, m), cur_est_cl(:, m));
                % in the event there's multiple peaks, this selects the
                % "mean"
                peak = round(mean(find(cur_xcorr == max(cur_xcorr))));
                offset_cl = offset_cl + cur_lags(peak);
            end
            offset_cl = round(offset_cl / nchan); % this gives the mean offset
            offset_cl_ms = offset_cl * dt*1000;

            % get maximum time-offset between the two (CBP)
            offset_cbp = 0;
            for m=1:nchan
                [cur_xcorr cur_lags] = xcorr(cur_true(:, m), cur_est_cbp(:, m));
                % in the event there's multiple peaks, this selects the
                % "mean"
                peak = round(mean(find(cur_xcorr == max(cur_xcorr))));
                offset_cbp = offset_cbp + cur_lags(peak);
            end
            offset_cbp = round(offset_cbp / nchan); % this gives the mean offset
            offset_cbp_ms = offset_cbp * dt*1000;



            off_min = -abs(max(offset_cbp, offset_cl)) + 1;
            off_max = abs(max(offset_cbp, offset_cl));
            % interpolate to get the expanded waveforms on a common domain,
            % then get the percentage of change
            sample_axis = 1:length(t_axis);
            expanded_sample_axis = ...
                [(off_min:0) sample_axis length(t_axis)+(1:off_max)];
            cur_true_expanded = interp1(1:length(t_axis), cur_true, ...
                expanded_sample_axis, 'pchip', 0);
            cur_est_cbp_expanded = interp1((1:length(t_axis)) + offset_cbp, cur_est_cbp, ...
                expanded_sample_axis, 'pchip', 0);
            cur_est_cl_expanded = interp1((1:length(t_axis)) + offset_cl, cur_est_cl, ...
                expanded_sample_axis, 'pchip', 0);

            err_cbp = norm(cur_true_expanded - cur_est_cbp_expanded, 'fro') / ...
                norm(cur_true_expanded, 'fro');
            err_cl = norm(cur_true_expanded - cur_est_cl_expanded, 'fro') / ...
                norm(cur_true_expanded, 'fro');

            % get individual channels, add as separate plots. number of cols is
            % number of channels
            plots = {};
            for m=1:size(cur_true, 2)
                if m ~= 1
                    legendargs = {'HandleVisibility', 'off'};
                else
                    legendargs = {};
                end

                % filter and whiten the true waveforms to compare to est
                plots{end+1} = [];
                plots{end}.x = t_axis;
                plots{end}.y = cur_true(:,m);
                plots{end}.args = {'Color', 'black', 'DisplayName', 'True'};
                plots{end}.args = {plots{end}.args{:} legendargs{:}};
                plots{end}.chan = m;
                plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};

                % final waveforms (CBP) - shifted to compensate for the shift
                % above
                plots{end+1} = [];
                plots{end}.x = t_axis + offset_cbp_ms;
                plots{end}.y = cur_est_cbp(:,m);
                plots{end}.args = {'Color', params.plotting.cell_color(c), 'DisplayName', 'CBP'};
                plots{end}.args = {plots{end}.args{:} legendargs{:}};
                plots{end}.chan = m;
                plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};

                % initial clustering waveforms - shifted to compensate for the shift
                % above
                plots{end+1} = [];
                plots{end}.x = t_axis + offset_cl_ms;
                plots{end}.y = cur_est_cl(:,m);
                plots{end}.args = {'--', 'Color', params.plotting.cell_color(c) * .8, 'DisplayName', 'Clus.'};
                plots{end}.args = {plots{end}.args{:} legendargs{:}};
                plots{end}.chan = m;
                plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
            end

            multiplot(plots);

            multiplotxlabel('Time (msec)')
            true_str = num2str(c);
            
            if best_ordering_cl(c) <= length(CBPdata.clustering.init_waveforms)
                cl_str = num2str(best_ordering_cl(c));
            else
                cl_str = "N/A";
            end
            
            if best_ordering_cbp(c) <= length(CBPdata.waveformrefinement.final_waveforms)
                cbp_str = num2str(best_ordering_cbp(c));
            else
                cbp_str = "N/A";
            end
            
            
            multiplotylabel(sprintf('True #%s/CBP #%s/Clus. #%s', ...
                                    true_str, cbp_str, cl_str));
            multiplotlegend('FontSize', 10);%, 'Location', 'SouthOutside', 'Orientation', 'Horizontal');

            num_spikes = length(CBPdata.groundtruth.spike_time_array_processed{c});
            multiplottitle(sprintf('%d spikes, RMS err: CBP=%.0f%%, Cl=%.0f%%', ...
                                   num_spikes, 100*err_cbp, 100*err_cl));

            % Due to MATLAB subplot(...) display bug, when we try to switch
            % subplots below, it overwrites the original. As a workaround,
            % just save each subplot axes handle in a cell array and do it
            % manually
            subplotaxes{n} = gca;
        end
    end
end

function changeCallback(varargin)
    global CBPdata params;

    % basic quantities
    num_est = CBPdata.waveformrefinement.num_waveforms;                         % number of estimated waveforms, without extra rows
    num_true = length(unique(CBPdata.groundtruth.true_spike_class));   % number of true waveforms, without extra columns

    % get new permutation
    if num_est == num_true
        dlgmsg = ['Enter new permutation as a vector, in which the ' ...
                  'nth entry is the estimated waveform ID assignment '...
                  'for ground truth ID #n. This is equivalent to ' ...
                  'entering the corresponding row for each column, ' ...
                  'starting at column #1.' newline newline ...
                  'Since there are equally many ground truth IDs and '...
                  'estimated IDs, each number must appear exactly once.'];
        defaultvals = num2str(CBPdata.groundtruth.best_ordering);
    elseif num_est < num_true
        dlgmsg = ['Enter new permutation as a vector, in which the ' ...
                  'nth entry is the estimated waveform ID assignment '...
                  'for ground truth ID #n. This is equivalent to ' ...
                  'entering the corresponding row for each column, ' ...
                  'starting at column #1.' newline newline ...
                  'Since there are more ground truth IDs than estimated '...
                  'IDs, some ground truth IDs will have to be unassigned. ' ...
                  'Put the value "0" in the nth column to make it ' ...
                  'unassigned. Please make sure each row number appears ' ...
                  'exactly once.'];
        tmpvals = CBPdata.groundtruth.best_ordering;
        tmpvals(tmpvals > num_est) = 0;
        defaultvals = num2str(tmpvals);
    elseif num_est > num_true
        dlgmsg = ['Enter new permutation as a vector, in which the ' ...
                  'nth entry is the estimated waveform ID assignment '...
                  'for ground truth ID #n. This is equivalent to ' ...
                  'entering the corresponding row for each column, ' ...
                  'starting at column #1.' newline newline ...
                  'Since there are less ground truth IDs than estimated '...
                  'IDs, some estimated IDs will have to be unassigned. ' ...
                  'Only enter as many values as there are true waveform ' ...
                  'ID numbers, and please make sure each row number ' ...
                  'appears no more than once.'];
        tmpvals = CBPdata.groundtruth.best_ordering;
        tmpvals = tmpvals(1:num_true);
        defaultvals = num2str(tmpvals);
    end
    dlgtext = inputdlg(dlgmsg, ...
                       'Enter New Permutation', 1, ...
                       {['[' defaultvals ']']});
    if isempty(dlgtext)
        return;
    end
    perm = str2num(dlgtext{1});

    ChangePermutation(perm);
    ChangeCalibrationTab('Assignment Error Matrix');
end
