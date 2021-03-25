% Calibration for waveform initialization:
% Fig 5 shows the data segments projected onto the first two principal components,
% and the identified clusters.  Fig 6 shows the waveforms associated with each
% cluster.  The visualization function also prints out a table of distances between
% waveforms, and each of their distances to the origin (i.e., their norm).  All
% distances are relative to the noise amplitude.  These numbers provide some
% indication of how likely it is that waveforms could be confused with each other, or
% with background noise.
%
% At this point, waveforms of all potential cells should be identified (NOTE:
% spike identification errors are irrelevant - only the WAVEFORMS matter).  If
% not, may need to adjust params.clustering.num_waveforms and re-run the clustering
% to identify more/fewer cells.  May also wish to adjust the
% params.general.spike_waveform_len, increasing it if the waveforms (Fig 5) are being
% chopped off, or shortening it if there is a substantial boundary region of silence.
% If you do this, you should go back and re-run starting from the whitening step,
% since the waveform_len affects the identification of noise regions.

function InitializeWaveformPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Initial Waveforms, PCs');
        DeleteCalibrationTab('Initial Waveforms, Shapes');
        DeleteCalibrationTab('Initial Waveforms, Cheat');
        DeleteCalibrationTab('Initial Waveforms, Comparison');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    % set up local vars
    XProj = CBPdata.clustering.XProj;
    assignments = CBPdata.clustering.assignments;
    X = CBPdata.clustering.X;
    nchan = CBPdata.whitening.nchan;
    dt = CBPdata.whitening.dt;

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    num_all_est_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:num_all_est_cells);
    num_plot_cells = length(plot_cells);
    CheckPlotCells(num_plot_cells);

    % only compute plot_centroids, proj_plot_centroids, etc for the cells being plotted.
    % note that the n'th column index corresponds to the cell `plot_cells(n)`, not just `n`.
    plot_centroids = zeros(size(X, 1), num_plot_cells);
    proj_plot_centroids = zeros(size(XProj,2), num_plot_cells);
    counts = zeros(num_plot_cells, 1);
    distances = zeros(size(X, 2),1);
    for n=1:length(plot_cells)
        spikeInds = find(assignments==plot_cells(n));
        plot_centroids(:, n) = mean(X(:, spikeInds), 2);
        proj_plot_centroids(:, n) = mean(XProj(spikeInds,:)', 2);
        counts(n) = length(spikeInds);
        distances(spikeInds) = sqrt(sum((XProj(spikeInds,:)' - ...
           repmat(proj_plot_centroids(:,n),1,counts(n))).^2))';     %%@ RMS vs L2?
    end

    % menu parameters
    menu_params = {"ButtonArgs", {'FontSize', 14, ...
                                  'String', 'Adjust...', ...
                                  'Units', 'normalized', ...
                                  'Position', [0.875 0 0.125 0.05]}, ...
                      "Entries", {{'Label', 'Merge...', ...
                                   'Callback', @(varargin) adjustCallback(@mergeCallback)}, ...
                                  {'Label', 'Split...', ...
                                   'Callback', @(varargin) adjustCallback(@splitCallback)}, ...
                                  {'Label', 'Reassess...', ...
                                   'Callback', @(varargin) adjustCallback(@reassessCallback)}, ...
                                  {'Label', 'Add...', ...
                                   'Callback', @(varargin) adjustCallback(@addCallback)}, ...
                                  {'Label', 'Remove...', ...
                                   'Callback', @(varargin) adjustCallback(@removeCallback)}}};

% -------------------------------------------------------------------------
% Plot PCs (Tab 1)
    t1 = CreateCalibrationTab('Initial Waveforms, PCs', 'InitializeWaveform');
    cla('reset');
    hold on;

    % X_cluster : time x snippet-index matrix of data
    % XProj_cluster : snippet x PC-component matrix of projections
    % cluster_assignments : vector of class assignments

    X_cluster = CBPdata.clustering.X;
    XProj_cluster = CBPdata.clustering.XProj;
    cluster_assignments = CBPdata.clustering.assignments;

    PlotPCA(X_cluster, XProj_cluster, cluster_assignments, ...
            params.clustering.num_waveforms);
    title(sprintf('Clustering result (%d clusters, %d plotted)', ...
                  num_all_est_cells, num_plot_cells));

    % Add merge/split buttons

    % Temporarily set look and feel. Taken from
    % http://undocumentedmatlab.com/blog/modifying-matlab-look-and-feel/
    %%@ javax.swing.UIManager.setLookAndFeel('javax.swing.plaf.metal.MetalLookAndFeel');
    %%@ ^^ NOTE: Metal no longer works on Mac R2019, so just use the default

    adjustbutton = popupmenu(t1, menu_params{:});

    % Ensure that the controls are fully-rendered before restoring the L&F
    drawnow;
    pause(0.05);

    % Restore original look and feel
    %%@ javax.swing.UIManager.setLookAndFeel(CBPInternals.original_LnF);
    %%@ ^^ NOTE: Metal no longer works on Mac R2019, so not necessary

%% -------------------------------------------------------------------------
% Waveform distances (Tab 2)
%%@ The original version of this tab didn't take into account when
%%@ identified clusters were different time-shifted versions of one another.
%%@ We have two different methods to make this comparison
    t2 = CreateCalibrationTab('Initial Waveforms, Comparison', 'InitializeWaveform');

    % First, get some local variables that we need.
    % We are going to compare *all* waveform centroids - not just those being
    % chosen as "active plot" waveforms. This matrix has each *flattened*
    % centroid as the column vectors, so the number of columns is the
    % number of *all* cells.
    % We also want to dynamically recompute the number of estimated cells
    % on-the-fly, as the user may have changed the
    % params.clustering.num_waveforms param and simply just have refreshed
    % the plot without recomputing...
    all_centroids = CBPdata.clustering.centroids;
	num_all_est_cells = size(all_centroids, 2);

    result = MeasureCentroidSimilarity(all_centroids, nchan, ...
                                       params.clustering.similarity_method);
    % Now we branch on the similarity method and calculate the similarity
    if isequal(params.clustering.similarity_method, "shiftcorr")
        titlestr = "Maximum reflective correlation coefficients for all possible waveform time shifts" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = false; % lighter values are *higher* correlation coefficients, which are worse
    elseif isequal(params.clustering.similarity_method, "shiftdist")
        titlestr = "Minimum RMS distances between all possible waveform time shifts" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = true; % lighter values are shorter distances, which are worse
    elseif isequal(params.clustering.similarity_method, "magspectrumcorr")
        titlestr = "Reflective correlation coefficients for magnitude spectra" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = false; % lighter values are *higher* correlation coefficients, which are worse
    elseif isequal(params.clustering.similarity_method, "magspectrumshift")
        titlestr = "RMS distances between magnitude spectra" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = true; % lighter values are shorter distances, which are worse
    elseif isequal(params.clustering.similarity_method, "simple")
        titlestr = "Simple, non-time-shifted RMS distances between waveforms" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = true; % lighter values are shorter distances, which are worse
    end

    % Now display and plot visually. We're going to both plot a colorful
    % representation of the value, as well as the numeric value in text.
    % For the diagonal, we just set the background color to black.
    fprintf(titlestr + ": \n");
    disp(result);
    if ~flipmap
        % set diagonal to 0
        result_no_diag = result .* (1 - eye(length(result)));
    elseif flipmap
        % set diagonal to max value
        result_no_diag = result .* (1 - eye(length(result)));
        result_no_diag = result_no_diag + ...
            diag(repmat(max(result_no_diag, [], 'all'), 1, length(result)));
    end
    imageax = imagesc(result_no_diag);
    % set axes, colormap, labels etc
    axis equal;
    axis tight;
    xlabel('Waveform ID');
    ylabel('Waveform ID');
    title(titlestr);

    % Now we also add the colorbar, which should be mostly gray - but
    % switch to red for the worst offenders!
    % If "flipmat" is set, that means that we went with a similarity method
    % in which lower scores are worse (e.g. "distance" between waveform
    % centroids)
    tmpmap = gray;
    % the "mask" turns higher values red
    mask = linspace(1, 0, floor(length(gray))/2)';
    mask = [ones(length(gray) - length(mask), 1); mask];
    tmpmap(:, 2:3) = ...
        tmpmap(:, 2:3) .* repmat(mask, 1, 2);
    if flipmap
        tmpmap = flipud(tmpmap); % lighter color = less errors
    end
    colormap(gca, tmpmap);
    c = colorbar("Direction", "reverse");
    if ~flipmap
        set(gca, 'CLim', [0 1]);
    else
        set(gca, 'CLim', [0 nanmax(result_no_diag, [], 'all')]);
    end

    % Now plot the text. We also need to set the font size - to do this, we
    % will get the size of the axes and divide by the number of clusters to
    % get the size of each box, and then set the font size accordingly.
    %
    % MATLAB doesn't give us a way to get the size of *only* the image
    % portion - only the entire axes, title, etc - so we will just estimate.
    % Turns out if we take the axis width and multiply by 0.4 (in
    % "normalized" units), we seem to get a decent font size that scales
    % well with the number of clusters, window size, etc.
    ax_size = get(gca, 'Position');
    box_size = ax_size(3)/num_all_est_cells * 0.375;
    for x=1:num_all_est_cells
        for y=1:num_all_est_cells
            if x == y
                textcolor = [1.0 1.0 0.0];
            else
                textcolor = [0.0 1.0 1.0];
            end
            text(x, y, num2str(result(x, y), '%5.3f'), ...
              'HorizontalAlignment', 'center', ...
              'Color', textcolor, ...
              'FontWeight', 'bold', ...
              'FontUnits', 'normalized', ...
              'FontSize', box_size);
        end
    end

    adjustbutton = popupmenu(t2, menu_params{:});


%% -------------------------------------------------------------------------
% If we're in "cheat mode," plot the comparison of the current waveforms to
% ground truth
    if params.ground_truth.cheat_mode
        t_cheat = CreateCalibrationTab('Initial Waveforms, Cheat', ...
                                       'InitializeWaveform');
        total_spikes_true = length(CBPdata.ground_truth.true_spike_times);
        total_spikes_cl = length(cell2mat(CBPdata.clustering.spike_time_array_cl));
        
        total_tp_combined_cl = sum(CBPdata.clustering.cheat_mode.total_true_positives_cl);
        total_fp_combined_cl = sum(CBPdata.clustering.cheat_mode.total_false_positives_cl);
        total_misses_combined_cl = sum(CBPdata.clustering.cheat_mode.total_misses_cl);
 
        num_true = length(unique(CBPdata.ground_truth.true_spike_class));
        num_est_cl = length(CBPdata.clustering.init_waveforms);
        PlotGroundTruthAssignmentMatrix(CBPdata.clustering.cheat_mode.tp_mtx_cl, ...
                                        CBPdata.clustering.cheat_mode.fp_mtx_cl, ...
                                        CBPdata.clustering.cheat_mode.miss_mtx_cl, ...
                                        num_true, num_est_cl, ...
                                        total_tp_combined_cl, ...
                                        total_fp_combined_cl, ...
                                        total_misses_combined_cl, ...
                                        total_spikes_cl, total_spikes_true, ...
                                        CBPdata.clustering.cheat_mode.best_ordering_cl, ...
                                        params.ground_truth.balanced, 'Clustering');        
    end
    
%% -------------------------------------------------------------------------
% Plot the time-domain snippets (Tab 3)
    t3 = CreateCalibrationTab('Initial Waveforms, Shapes', 'InitializeWaveform');

    % number of cols, rows, and window length
    nc = ceil(sqrt(num_plot_cells));
    nr = ceil((num_plot_cells)/nc);
    wlen = size(X, 1) / nchan;

    % cluster vertical range, maximum number of waveforms to plot
    X_visible = X(:, ismember(assignments, plot_cells));
    MAX_TO_PLOT = 1e2;

    % time axis and axis limits
    t_ms = (1:wlen)*dt*1000;
    max_xlim = [min(t_ms) max(t_ms)];
    max_ylim = [min(X_visible(:)) max(X_visible(:))];

    hold on;
    subplotaxes = {};
    for n = 1:length(plot_cells)
        c = plot_cells(n);
        % X are the individual waveforms. get the subset of X corresponding
        % to the current cluster.
        Xsub = X(:, assignments == c);
        centroid = plot_centroids(:,n);

        % If we have more waveforms than the max we want to plot, take a random
        % sample of `MAX_TO_PLOT` waveforms, without replacement
        if (size(Xsub, 2) > MAX_TO_PLOT)
            Xsub = Xsub(:, randsample(size(Xsub, 2), MAX_TO_PLOT, false));
        end

        % Do the plot
        plots = {};
        subplot(nr, nc, n);

        % MATLAB bugfix - by setting the fontsize of the under_panel axes like this
        % in advance, multiplot panel knows to reserve enough space
        set(gca, 'FontSize', 18);

        % do plots
        for m=1:nchan
            % MUCH faster speedup - concatenate all plots to one
            % lineseries, using "NaN's" as spacers
            num_snippets = size(Xsub, 2);
            x = t_ms;
            xx = repmat([x NaN], 1, num_snippets);
            y = Xsub((m-1)*wlen+1:m*wlen,:);
            y = [y;NaN + zeros(1, num_snippets)];
            yy = y(:);

            plots{end+1} = [];
            plots{end}.x = xx;
            plots{end}.y = yy;
            plots{end}.args = {'Color', 0.25*params.plotting.cell_color(c)+0.75*[1 1 1]};
            plots{end}.chan = m;
            plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};

            plots{end+1} = [];
            plots{end}.x = t_ms;
            plots{end}.y = centroid((m-1)*wlen+1:m*wlen,:);
            plots{end}.args = { 'Color', params.plotting.cell_color(c), 'LineWidth', 2};
            plots{end}.chan = m;
            plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
        end

        multiplot(plots);

        % set plot attributes
        %multiplotdummyfunc(@set, 'FontSize', 12);   % font for title and labels
        %multiplotsubfunc(@set, 'FontSize', 10);     % font for subplot axes
        multiplotxlabel('Time (ms)');
        multiplotylabel("Cell " + c);
        n_spikes = nnz(assignments == c);
        SNR = rms(plot_centroids(:,n));                  % note that standard deviation is 1
        stdev = rms(rms(X(:, assignments == c) - plot_centroids(:, c)));
        multiplottitle(sprintf('%d spikes, SNR=%.1f, \x3C3_{RMS}=%.1f', ...
                               n_spikes, SNR, stdev));

        % Due to MATLAB subplot(...) display bug, when we try to switch
        % subplots below, it overwrites the original. As a workaround,
        % just save each subplot axes handle in a cell array and do it
        % manually
        subplotaxes{n} = gca;
    end

    adjustbutton = popupmenu(t3, menu_params{:});

end

% wrapper function for error handling
function adjustCallback(func_handle)
    global params
    if params.general.raw_errors
        func_handle();
    else
        try
            func_handle();
        catch err
            errordlg(sprintf("There was an error while processing.\n" + ...
                             "\n" + ...
                             "Error message is below:\n" + ...
                             "===\n%s\n" + ...
                             "===\n\nMore detail may be in the command window.", ...
                             err.message), "Processing Error", "modal");
            rethrow(err);
        end
    end
end

function mergeCallback(varargin)
    global params;
    dlgtext = inputdlg(['Enter list of clusters to merge (1-' num2str(params.clustering.num_waveforms) '), ' ...
                        'separated by space:'], ...
                        'Merge Clusters');

    if ~isempty(dlgtext) && ~isempty(dlgtext{1})
            to_merge = dlgtext{1};
            to_merge = strrep(to_merge,',',' ');    %just in case they put commas
            to_merge = strsplit(strtrim(to_merge), ' ');
            to_merge = cellfun(@str2num,to_merge);

            MergeClusters(to_merge);
    end
end

function splitCallback(varargin)
    global params;

    dlgtext = inputdlg(['Enter cluster to split (1-' num2str(params.clustering.num_waveforms) '):'], ...
                        'Split Clusters');
    if isempty(dlgtext) && ~isempty(dlgtext{1})
        return;
    end

    dlgtext2 = inputdlg('Enter number of clusters to split into:', 'Split Clusters');
    if isempty(dlgtext2) && ~isempty(dlgtext2{1})
        return;
    end

    to_split = str2num(strtrim(dlgtext{1}));
    num_splits = str2num(dlgtext2{1});

    SplitCluster(to_split, num_splits);
end

function reassessCallback(varargin)
    global params;
    dlgtext = inputdlg(['This method "reassesses" a set of erroneous ' ...
                        'waveforms by removing all other estimated waveforms ' ...
                        'from the signal, and then re-clustering the residue ' ...
                        'to produce a new set of waveforms that can be re-sorted.' newline ...
                          newline ...
                        'Enter list of waveform IDs to reassess (1-' num2str(params.clustering.num_waveforms) '), ' ...
                        'separated by space:'], ...
                        'Reassess Clusters');

    if ~isempty(dlgtext) && ~isempty(dlgtext{1})
        to_reassess = dlgtext{1};
        to_reassess = strrep(to_reassess,',',' ');    %just in case they put commas
        to_reassess = strsplit(strtrim(to_reassess), ' ');
        to_reassess = cellfun(@str2num,to_reassess);

        ReassessClusters(to_reassess);
    end
end

function addCallback(varargin)
    global params;
    dlgtext = inputdlg(['This method "adds" a new cluster to the set of existing ' ...
                        'clusters by removing *all* estimated waveforms ' ...
                        'from the signal, and then clustering the residue ' ...
                        'to produce a new set of waveforms that are added to ' ...
                        'the existing set of clusters.' newline ...
                          newline ...
                        'Enter number of new clusters to add:'], ...
                        'Add Clusters');

    if ~isempty(dlgtext) && ~isempty(dlgtext{1})
        to_add = dlgtext{1};
        to_add = strrep(to_add,',',' ');    %just in case they put commas
        to_add = strsplit(strtrim(to_add), ' ');
        to_add = cellfun(@str2num,to_add);

        AddClusters(to_add);
    end
end

function removeCallback(varargin)
    global params;
    dlgtext = inputdlg(['This method "removes" a set of clusters from the existing ' ...
                        'clusters by simply dropping that cluster without splitting ' ...
                        'or merging anything else.' ...
                        newline ...
                        'Enter cluster IDs to remove:'], ...
                        'Remove Clusters');

    if ~isempty(dlgtext) && ~isempty(dlgtext{1})
        to_remove = dlgtext{1};
        to_remove = strrep(to_remove,',',' ');    %just in case they put commas
        to_remove = strsplit(strtrim(to_remove), ' ');
        to_remove = cellfun(@str2num,to_remove);

        RemoveClusters(to_remove);
    end
end
