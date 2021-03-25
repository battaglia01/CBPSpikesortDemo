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
    font_size = 12; % font size for text

    best_ordering_cl = CBPdata.ground_truth.best_ordering_cl;
    best_ordering_cbp = CBPdata.ground_truth.best_ordering_cbp;
    % these are the false negative/false positive/combined error matrices,
    % which have rows as estimated waveform ID #'s and cols as true
    % waveform ID #'s

    %%@ this gets all the things mapped to
    %%@ each ground truth category (i.e. column)
    %%@ this happens in a few places - search for more %%@ comments
    get_best_ordering_cl = @(x) find(best_ordering_cl(:, x));
    get_best_ordering_cbp = @(x) find(best_ordering_cbp(:, x));

    %%@ note: in both situations we use the "best_ordering" assignments
    %%above
    miss_mtx_cl = CBPdata.ground_truth.miss_mtx_cl;
    fp_mtx_cl = CBPdata.ground_truth.fp_mtx_cl;
    tp_mtx_cl = CBPdata.ground_truth.tp_mtx_cl;

    miss_mtx_cbp = CBPdata.ground_truth.miss_mtx_cbp;
    fp_mtx_cbp = CBPdata.ground_truth.fp_mtx_cbp;
    tp_mtx_cbp = CBPdata.ground_truth.tp_mtx_cbp;

    % Are we using an external spikesorter for our clustering comparison?
    using_external = isfield(CBPdata, 'external');
    
    % number of true waveforms, without extra columns
    num_true = length(unique(CBPdata.ground_truth.true_spike_class));
    % number of estimated clustering waveforms, without extra rows
    num_est_cl = length(CBPdata.ground_truth.clustering.init_waveforms);
    % number of estimated CBP waveforms, without extra rows
    num_est_cbp = length(CBPdata.waveform_refinement.final_waveforms);

    % these are the total number of false negatives/positives, and spikes
    total_tp_combined_cl = sum(CBPdata.ground_truth.total_true_positives_cl);
    total_misses_combined_cl = sum(CBPdata.ground_truth.total_misses_cl);
    total_fp_combined_cl = sum(CBPdata.ground_truth.total_false_positives_cl);
    total_tp_cbp = sum(CBPdata.ground_truth.total_true_positives_cbp);
    total_misses_cbp = sum(CBPdata.ground_truth.total_misses_cbp);
    total_fp_cbp = sum(CBPdata.ground_truth.total_false_positives_cbp);
    total_spikes_true = length(CBPdata.ground_truth.true_spike_times);
    total_spikes_cl = sum(cellfun(@length, CBPdata.ground_truth.clustering.spike_time_array_cl));
    total_spikes_cbp = sum(cellfun(@length, CBPdata.waveform_refinement.spike_time_array_thresholded));

    if CBPdata.ground_truth.blank_ground_truth
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
    if using_external
        label_name = 'External';
    else
        label_name = 'Clustering';
    end
    PlotGroundTruthAssignmentMatrix(tp_mtx_cl, fp_mtx_cl, miss_mtx_cl, ...
                                    num_true, num_est_cl, ...
                                    total_tp_combined_cl, total_fp_combined_cl, total_misses_combined_cl, ...
                                    total_spikes_cl, total_spikes_true, ...
                                    best_ordering_cl, ...
                                    params.ground_truth.balanced, label_name);
    ground_truth_note = uicontrol(maintab, ground_truth_note_params{:});
    changebutton = uicontrol(maintab, 'Tag', 'ground_truth_permutation', ...
                             'Style', 'pushbutton', ...
                             'FontSize', 14, ...
                             'String', 'Adjust Assignments...', ...
                             'Units', 'normalized', ...
                             'Position', [0 0 0.25 0.05], ...
                             'Callback', @(varargin) adjustAssignmentCallback(best_ordering_cl, 'clustering'));

%% -------------------------------------------------------------------------
% Plotting false negatives and positives for CBP
    maintab = CreateCalibrationTab('CBP Error Matrix', 'GroundTruth');
    PlotGroundTruthAssignmentMatrix(tp_mtx_cbp, fp_mtx_cbp, miss_mtx_cbp, ...
                                    num_true, num_est_cbp, ...
                                    total_tp_cbp, total_fp_cbp, total_misses_cbp, ...
                                    total_spikes_cbp, total_spikes_true, ...
                                    best_ordering_cbp, ...
                                    params.ground_truth.balanced, 'CBP');
    ground_truth_note = uicontrol(maintab, ground_truth_note_params{:});
    changebutton = uicontrol(maintab, 'Tag', 'ground_truth_permutation', ...
                             'Style', 'pushbutton', ...
                             'FontSize', 14, ...
                             'String', 'Adjust Assignments...', ...
                             'Units', 'normalized', ...
                             'Position', [0 0 0.25 0.05], ...
                             'Callback',  @(varargin) adjustAssignmentCallback(best_ordering_cbp, 'cbp'));


%% -------------------------------------------------------------------------
% Comparing true waveforms for CBP and Clustering
    if isfield(CBPdata.ground_truth, 'true_spike_waveforms')
        maintab = CreateCalibrationTab('True Waveform Comparison', ...
                                       'GroundTruth');

        dt = CBPdata.whitening.dt;
        nchan = size(CBPdata.whitening.data,1);
        assignments = CBPdata.ground_truth.assignments;

        plot_cells = intersect(CBPInternals.cells_to_plot, 1:num_true);
        num_plot_cells = length(plot_cells);
        CheckPlotCells(num_plot_cells);

        nc = ceil(sqrt(num_plot_cells));
        nr = ceil(num_plot_cells / nc);

        % first, take the ground truth waveforms and filter/whiten them
        % using the same settings as the original signal
        refiltered_trues = ...
            RefilterAndWhitenWaveforms(...
                CBPdata.ground_truth.true_spike_waveforms, ...
                CBPdata.filtering.coeffs, ...
                CBPdata.whitening.old_acfs, ...
                CBPdata.whitening.old_cov, ...
                params.whitening.reg_const);

        % First, let's get all of our waveforms ready. We'll also get the
        % axis limits in advance - it makes plotting easier
        % t_axis is the "time" x-axis we'll be using...
        t_axis = (1:size(CBPdata.waveform_refinement.final_waveforms{1},1))*dt*1000;
        max_xlim = [min(t_axis) max(t_axis)];
        max_ylim = [Inf -Inf];

        % Let's get some more useful variables set up...
        % This is a cell array of cell arrays. The nth entry in the outer
        % level is the subplot, and within that are all the waveforms being
        % plotted.
        plots = {};
        % And these are the assignment indices for the things we actually
        % plot. So if we end up plotting assignments{1}, assignments{3},
        % etc then this will be [1 3 ...];
        plotted_assignment_indices = [];
        % This is a cell array of the errors for eaah assignment triple.
        % Each entry is an object with two properties - "cl" and "cbp". The
        % first is the clustering error (relative to true) and the second
        % is the CBP error (relative to true). The RMS error is used for
        % both.
        errs = {};
        for n=1:length(assignments)
            % Make sure this is really a true cell; e.g. it isn't "0" or
            % some kind of dummy waveform.
            %%@ NOTE: dummy waveforms are now filtered out in
            %%@ CalculateAssignmentTriples, but left for reference.
            if ~ismember(assignments{n}.true, 1:num_true) || ...
               ~ismember(assignments{n}.true, plot_cells)
                continue;
            end

            % Add a subplot entry, a new entry for calculated error, and
            % save the current assignment index for reference
            plots{end+1} = {};
            errs{end+1} = [];
            plotted_assignment_indices(end+1) = n;

            % Get the indices for the true, clustering, and CBP waveforms.
            % (There may be more than one for Cl and CBP)
            cur_true_idx = assignments{n}.true;
            cur_cl_idx = assignments{n}.cl;
            cur_cbp_idx = assignments{n}.cbp;

            % get current true and estimated waveforms. Remember there may
            % be more than one match
            cur_true_waveform = refiltered_trues{cur_true_idx};
            cur_cl_waveforms = {};
            cl_offsets = {};
            cur_cbp_waveforms = {};
            cbp_offsets = {};

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % True waveform
            % Normalize the true waveform by the frobenius norm (e.g. the
            % L2 norm of the flattened vector). Our call to `fillmissing`
            % also gets rid of NaNs
            cur_true_waveform = ...
                fillmissing(cur_true_waveform./...
                                norm(cur_true_waveform, 'fro'), ...
                            'constant', 0);
            % Also update the min/max ylim
            tmp_ylim = [min(cur_true_waveform(:)) max(cur_true_waveform(:))];
            max_ylim(1) = min(tmp_ylim(1), max_ylim(1));
            max_ylim(2) = max(tmp_ylim(2), max_ylim(2));
            % Add channels to plot
            for o=1:size(cur_true_waveform, 2)
                if o ~= 1
                    legendargs = {'HandleVisibility', 'off'};
                else
                    legendargs = {};
                end
                plots{n}{end+1} = [];
                plots{n}{end}.x = t_axis;
                plots{n}{end}.y = cur_true_waveform(:,o);
                plots{n}{end}.args = {'Color', 'black', 'DisplayName', 'True'};
                plots{n}{end}.args = {plots{n}{end}.args{:} legendargs{:}};
                plots{n}{end}.chan = o;
                % Don't add the axis limits yet - at the end we'll go
                % through all of these again and update the limits.
                %%@ left for reference
                %%@ plots{n}{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
            end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Clustering waveform
            % Get all the clustering waveforms
            % At the end, if cur_cl_waveforms is still empty, then we had no
            % waveform for it at all, so just set it to zero.
            err_cl = 0;
            num_cl_valid = 0; % save this so we can take the average later
            for m=1:length(cur_cl_idx)
                % check this isn't a dummy waveform
                %%@ NOTE - probably unnecessary since we do this already in
                %%@ CalculateAssignmentTriples, but left for clarity
                if cur_cl_idx(m) == 0 || cur_cl_idx(m) > num_est_cl
                    continue;
                end
                num_cl_valid = num_cl_valid + 1;
                new_waveform_cl = CBPdata.ground_truth.clustering.init_waveforms{cur_cl_idx(m)};

                % Normalize the true waveform by the frobenius norm (e.g. the
                % L2 norm of the flattened vector). Our call to `fillmissing`
                % also gets rid of NaNs
                new_waveform_cl = ...
                fillmissing(new_waveform_cl./...
                                norm(new_waveform_cl, 'fro'), ...
                            'constant', 0);

                % Also update the min/max ylim
                tmp_ylim = [min(new_waveform_cl) max(new_waveform_cl)];
                max_ylim(1) = min(tmp_ylim(1), max_ylim(1));
                max_ylim(2) = max(tmp_ylim(2), max_ylim(2));

                % Get offset from ground truth
                % To do this, first pad both waveforms with zeros, and
                % then take the flattened xcorr
                cur_true_waveform_pad_flat = ...
                    reshape([cur_true_waveform;zeros(size(cur_true_waveform))], ...
                            [], 1);
                cur_cl_waveform_pad_flat = ...
                    reshape([new_waveform_cl;zeros(size(new_waveform_cl))], ...
                            [], 1);
                [cur_xcorr, cur_lags] = xcorr(cur_true_waveform_pad_flat, cur_cl_waveform_pad_flat);
                best_lag = cur_lags(cur_xcorr == max(cur_xcorr));

                % Shift estimated waveform to match true
                cur_cl_waveform_pad_flat = ...
                    circshift(cur_cl_waveform_pad_flat, best_lag);

                new_waveform_cl = reshape(cur_cl_waveform_pad_flat, [], nchan);
                new_waveform_cl = new_waveform_cl(1:size(cur_true_waveform, 1), :);

                % add to end
                cur_cl_waveforms{end+1} = new_waveform_cl;

                % Add channels to plot
                for o=1:size(new_waveform_cl, 2)
                    if o ~= 1 || m ~= 1
                        legendargs = {'HandleVisibility', 'off'};
                    else
                        legendargs = {};
                    end
                    plots{n}{end+1} = [];
                    plots{n}{end}.x = t_axis;
                    plots{n}{end}.y = new_waveform_cl(:,o);
                    plots{n}{end}.args = ...
                        {'--', ...
                         'Color', params.plotting.cell_color(cur_true_idx) * .8, ...
                         'DisplayName', 'Clus.'};
                    plots{n}{end}.args = {plots{n}{end}.args{:} legendargs{:}};
                    plots{n}{end}.chan = o;
                    % Don't add the axis limits yet - at the end we'll go
                    % through all of these again and update the limits.
                    %%@ left for reference
                    %%@ plots{n}{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
                end

                cur_err_cl = norm(new_waveform_cl - cur_true_waveform, 'fro') / ...
                    norm(cur_true_waveform, 'fro');
                err_cl = err_cl + cur_err_cl;
            end
            % Now just add the error to the errors list
            err_cl = err_cl / num_cl_valid;
            errs{end}.err_cl = err_cl;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % CBP waveform
            % Get all the CBP waveforms
            % At the end, if cur_cbp_waveforms is still empty, then we had no
            % waveform for it at all, so just set it to zero.
            err_cbp = 0;
            num_cbp_valid = 0; % save this so we can take the average later
            for m=1:length(cur_cbp_idx)
                % check this isn't a dummy waveform
                %%@ NOTE - probably unnecessary since we do this already in
                %%@ CalculateAssignmentTriples, but left for clarity
                if cur_cbp_idx(m) == 0 || cur_cbp_idx(m) > num_est_cbp
                    continue;
                end
                num_cbp_valid = num_cbp_valid + 1;
                new_waveform_cbp = CBPdata.waveform_refinement.final_waveforms{cur_cbp_idx(m)};

                % Normalize the true waveform by the frobenius norm (e.g. the
                % L2 norm of the flattened vector). Our call to `fillmissing`
                % also gets rid of NaNs
                new_waveform_cbp = ...
                fillmissing(new_waveform_cbp./...
                                norm(new_waveform_cbp, 'fro'), ...
                            'constant', 0);

                % Also update the min/max ylim
                tmp_ylim = [min(new_waveform_cbp) max(new_waveform_cbp)];
                max_ylim(1) = min(tmp_ylim(1), max_ylim(1));
                max_ylim(2) = max(tmp_ylim(2), max_ylim(2));

                % Get offset from ground truth
                % To do this, first pad both waveforms with zeros, and
                % then take the flattened xcorr
                cur_true_waveform_pad_flat = ...
                    reshape([cur_true_waveform;zeros(size(cur_true_waveform))], ...
                            [], 1);
                cur_cbp_waveform_pad_flat = ...
                    reshape([new_waveform_cbp;zeros(size(new_waveform_cbp))], ...
                            [], 1);
                [cur_xcorr, cur_lags] = xcorr(cur_true_waveform_pad_flat, cur_cbp_waveform_pad_flat);
                best_lag = cur_lags(cur_xcorr == max(cur_xcorr));

                % Shift estimated waveform to match true
                cur_cbp_waveform_pad_flat = ...
                    circshift(cur_cbp_waveform_pad_flat, best_lag);

                new_waveform_cbp = reshape(cur_cbp_waveform_pad_flat, [], nchan);
                new_waveform_cbp = new_waveform_cbp(1:size(cur_true_waveform, 1), :);

                % add to end
                cur_cbp_waveforms{end+1} = new_waveform_cbp;

                % Add channels to plot
                for o=1:size(new_waveform_cbp, 2)
                    if o ~= 1 || m ~= 1
                        legendargs = {'HandleVisibility', 'off'};
                    else
                        legendargs = {};
                    end
                    plots{n}{end+1} = [];
                    plots{n}{end}.x = t_axis;
                    plots{n}{end}.y = new_waveform_cbp(:,o);
                    plots{n}{end}.args = {'Color', params.plotting.cell_color(cur_true_idx) * .8, ...
                                          'DisplayName', 'CBP'};
                    plots{n}{end}.args = {plots{n}{end}.args{:} legendargs{:}};
                    plots{n}{end}.chan = o;
                    % Don't add the axis limits yet - at the end we'll go
                    % through all of these again and update the limits.
                    %%@ left for reference
                    %%@ plots{n}{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
                end

                cur_err_cbp = norm(new_waveform_cbp - cur_true_waveform, 'fro') / ...
                    norm(cur_true_waveform, 'fro');
                err_cbp = err_cbp + cur_err_cbp;
            end
            % Now just add the error to the errors list
            err_cbp = err_cbp / num_cbp_valid;
            errs{end}.err_cbp = err_cbp;
        end

        % Now we've got all of our waveforms and multiplots ready. We'll go
        % back through these and update the axis limits, then plot.
        % The outer loop goes through the different subplots...
        for n=1:length(plots)
            subplot(nr, nc, n);
            % ... and the inner loop goes through the individual channels
            % plotted in each one. Ground truth, Clustering, and CBP
            % waveforms are all elements in this subplot.
            for m=1:length(plots{n})
                plots{n}{m}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
            end

            % Now multiplot the current plot{n}
            multiplot(plots{n});

            % Now we're going to add the various labels. To do this we need
            % to get the current "assignment" being plotted...
            cur_assignment = assignments{plotted_assignment_indices(n)};

            % Get the true/cl/cbp indices being currently plotted.
            cur_true_idx = cur_assignment.true;
            cur_cl_idx = cur_assignment.cl;
            cur_cbp_idx = cur_assignment.cbp;

            % Get rid of invalid indices.
            %%@ NOTE: These have already been "pre-filtered" to remove
            %%@ dummy and etc. waveforms, but we're just leaving it for
            %%@ reference.
            cur_true_idx = ...
                cur_true_idx(cur_true_idx > 0 & cur_true_idx <= num_true);
            cur_cl_idx = ...
                cur_cl_idx(cur_cl_idx > 0 & cur_cl_idx <= num_est_cl);
            cur_cbp_idx = ...
                cur_cbp_idx(cur_cbp_idx > 0 & cur_cbp_idx <= num_est_cbp);

            % Generate the labeling str's for true, cl, and cbp
            true_str = cur_true_idx;
            cl_str = strjoin(string(cur_cl_idx), ", ");
            cbp_str = strjoin(string(cur_cbp_idx), ", ");

            if cl_str == ""
                cl_str = "N/A";
            end
            if cbp_str == ""
                cbp_str = "N/A";
            end

            multiplotxlabel('Time (ms)')
            multiplotylabel(sprintf('Tr#%s/CBP#%s/Cl#%s', ...
                                    true_str, cbp_str, cl_str));
            multiplotlegend('FontSize', 10);%, 'Location', 'SouthOutside', 'Orientation', 'Horizontal');

            % Now get error. If this is NaN it means our resulting error
            % was 0/0, so just make it "N/A" instead
            if ~isnan(errs{n}.err_cbp)
                err_cbp_str = sprintf("%.0f%%", 100*errs{n}.err_cbp);
            else
                err_cbp_str = "N/A";
            end
            if ~isnan(errs{n}.err_cl)
                err_cl_str = sprintf("%.0f%%", 100*errs{n}.err_cl);
            else
                err_cl_str = "N/A";
            end
            cur_num_true = length(CBPdata.ground_truth.spike_time_array_processed{cur_true_idx});
            multiplottitle(sprintf('%d sp., RMS err: CBP=%s, Cl=%s', ...
                                   cur_num_true, err_cbp_str, err_cl_str));

            % Due to MATLAB subplot(...) display bug, when we try to switch
            % subplots below, it overwrites the original. As a workaround,
            % just save each subplot axes handle in a cell array and do it
            % manually
            subplotaxes{n} = gca;
        end
    end
end

function out = getCellArrayFromAssignmentMatrix(mtx, num_rows, num_cols)
    % get current permutation as a cell array of indices
    cur_perm_str = '';
    for n=1:size(mtx, 2)
        cur_col = mtx(:, n);
        cur_entries = find(cur_col);
        cur_entries(cur_entries>num_rows) = 0;
        cur_ent_str = "";
        if length(cur_entries) == 1
            cur_ent_str = num2str(cur_entries);
        else
            cur_ent_str = ['[' num2str(cur_entries) ']'];
        end

        cur_perm_str = [cur_perm_str ', ' cur_ent_str];
    end
    % The first two chars will be ', ', so trim those
    cur_perm_str = cur_perm_str(3:end);
    out = cur_perm_str;
end

function adjustAssignmentCallback(best_ordering, type)
    global CBPdata params;

    % basic quantities
    if type == "cbp"
        num_est = CBPdata.waveform_refinement.num_waveforms;                % number of estimated waveforms, without extra rows
    elseif type == "clustering"
        num_est = CBPdata.ground_truth.clustering.num_waveforms;                         % number of estimated waveforms, without extra rows
    else
        error("adjustAssignmentCallback: 'type' must be either 'clustering' or 'cbp'!");
    end
    num_true = length(unique(CBPdata.ground_truth.true_spike_class));   % number of true waveforms, without extra columns


    % get new permutation
    if num_est == num_true
        dlgmsg = ['Enter new permutation as a cell array, in which the ' ...
                  'nth entry is the estimated waveform ID assignment '...
                  'for ground truth ID #n. This is equivalent to ' ...
                  'entering the corresponding row for each column, ' ...
                  'starting at column #1.' newline newline ...
                  'Since there are equally many ground truth IDs and '...
                  'estimated IDs, each number must appear exactly once.'];
        tmpvals = best_ordering;
    elseif num_est < num_true
        dlgmsg = ['Enter new permutation as a cell array, in which the ' ...
                  'nth entry is the estimated waveform ID assignment '...
                  'for ground truth ID #n. This is equivalent to ' ...
                  'entering the corresponding row for each column, ' ...
                  'starting at column #1.' newline newline ...
                  'Since there are more ground truth IDs than estimated '...
                  'IDs, some ground truth IDs will have to be unassigned. ' ...
                  'Put the value "0" in the nth column to make it ' ...
                  'unassigned. Please make sure each row number appears ' ...
                  'exactly once.'];
        tmpvals = best_ordering;
        tmpvals(tmpvals > num_est) = 0;
    elseif num_est > num_true
        % For this situation, and only for this situation, we need to
        % determine if the matrix is balanced or not. If it isn't balanced,
        % they can input multiple rows per column. If it is, they must
        % input only one.
        if params.ground_truth.balanced
            dlgmsg = ['Enter new permutation as a cell array, in which the ' ...
                      'nth entry is the estimated waveform ID assignment '...
                      'for ground truth ID #n. This is equivalent to ' ...
                      'entering the corresponding row for each column, ' ...
                      'starting at column #1.' newline newline ...
                      'Since there are less ground truth IDs than estimated '...
                      'IDs, some estimated IDs will have to be unassigned. ' ...
                      'Only enter as many values as there are true waveform ' ...
                      'ID numbers, and please make sure each row number ' ...
                      'appears no more than once.'];
            tmpvals = best_ordering;
            tmpvals = tmpvals(1:num_true);
        else
            dlgmsg = ['Enter new permutation as a cell array, in which the ' ...
                      'nth entry is the estimated waveform ID assignment '...
                      'for ground truth ID #n. This is equivalent to ' ...
                      'entering the corresponding row for each column, ' ...
                      'starting at column #1.' newline newline ...
                      'Since there are less ground truth IDs than estimated '...
                      'IDs, some estimated IDs will have to appear more than once. ' ...
                      'For any column with multiple estimated IDs, please enter ' ...
                      'them as a vector at the corresponding cell array index, ' ...
                      'such as {1, 2, [3 4], 5}. ' newline ...
                      'Please enter as many values as there are true waveform ' ...
                      'ID numbers, and please make sure each row number ' ...
                      'appears exactly once somewhere.'];
            tmpvals = best_ordering;
            tmpvals = tmpvals(1:num_true);
        end
    end
    defaultvals = getCellArrayFromAssignmentMatrix(tmpvals, num_est, num_true);
    dlgtext = inputdlg(dlgmsg, ...
                       'Enter New Permutation', 1, ...
                       {['{' defaultvals '}']});
    if isempty(dlgtext)
        return;
    end
    perm = eval(dlgtext{1});

    ChangeGroundTruthAssignments(perm, num_est, num_true, type);
    ChangeCalibrationTab('Assignment Error Matrix');
end
