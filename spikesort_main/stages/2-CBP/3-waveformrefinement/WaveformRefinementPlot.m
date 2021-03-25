% Calibration for CBP waveforms:
% If recovered waveforms differ significantly from initial waveforms, then algorithm
% has not yet converged - do another iteration of CBP.

function WaveformRefinementPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 && isequal(command,'disable')
        DeleteCalibrationTab('Waveform Refinement, PCs');
        DeleteCalibrationTab('Waveform Refinement, Comparison');
        DeleteCalibrationTab('Waveform Refinement, Waveforms');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    % set up local vars
    true_num_cells = CBPdata.waveform_refinement.num_waveforms;
    true_num_init_CBP = length(CBPdata.CBP.init_waveforms);
    true_num_clusters = length(CBPdata.clustering.init_waveforms);
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_plot_cells = length(plot_cells);
    CheckPlotCells(num_plot_cells);
    cluster_assignment_mtx = ...
        CBPdata.waveform_refinement.cluster_assignment_mtx;
    init_assignment_mtx = ...
        CBPdata.waveform_refinement.init_assignment_mtx;

    dt = CBPdata.whitening.dt;
    nchan = size(CBPdata.whitening.data,1);
    waveform_len = params.general.spike_waveform_len;

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


%% -------------------------------------------------------------------------
% Waveform PCs (Tab 1)
    t1 = CreateCalibrationTab('Waveform Refinement, PCs', 'WaveformRefinement');
    cla('reset');
    X_refined = CBPdata.waveform_refinement.X;
    XProj_refined =  CBPdata.waveform_refinement.XProj;
    assignments_refined =  CBPdata.waveform_refinement.assignments;

    PlotPCA(X_refined, XProj_refined, assignments_refined, ...
            true_num_cells);
    title(sprintf('Refined waveform result (%d CBP spike types, %d plotted)', ...
                  true_num_cells, num_plot_cells));

    adjustbutton = popupmenu(t1, menu_params{:});
%% -------------------------------------------------------------------------
% Waveform distances (Tab 2)
%%@ The original version of this tab didn't take into account when
%%@ identified clusters were different time-shifted versions of one another.
%%@ We have two different methods to make this comparison
    t2 = CreateCalibrationTab('Waveform Refinement, Comparison', 'WaveformRefinement');

    % first, get *all* centroids, not just those being plotted
    plot_centroids = [];
    all_centroids = [];
    for n=1:length(CBPdata.waveform_refinement.final_waveforms)
        all_centroids(:, end+1) = ...
            CBPdata.waveform_refinement.final_waveforms{n}(:);

        if ismember(n, plot_cells)
            plot_centroids(:, end+1) = ...
                CBPdata.waveform_refinement.final_waveforms{n}(:);
        end
    end
	true_num_cells = size(all_centroids, 2);

    % also, pad the centroids with zero values between each channel, so we
    % aren't just naively xcorring the flattened vector
    padded_centroids = [];
    for n=1:true_num_cells
        tmp_centroid = all_centroids(:, n);
        tmp_centroid = reshape(tmp_centroid, [], nchan);
        tmp_centroid = [tmp_centroid; zeros(size(tmp_centroid))];
        padded_centroids(:, n) = tmp_centroid(:);
    end

    % now, depending on how our param is set, we get the distance matrix
    % using one of three methods
    ip = zeros(true_num_cells); % this is the matrix of dot products

    if isequal(params.clustering.similarity_method, "shiftcorr")
        % this method gets the shortest distance between all possible shifts of
        % waveforms with one another, e.g. it gets the max value of the
        % xcorr between them.
        %
        %%@ use the padded centroids here so we aren't xcorring between
        %%@channels
        ip = zeros(true_num_cells);
        for r=1:true_num_cells
            for c=r:true_num_cells
                if r == c
                    ip(r, r) = norm(all_centroids(:, r))^2;
                else
                    ip(r, c) = max(xcorr(padded_centroids(:, r), padded_centroids(:, c)));
                    ip(c, r) = max(xcorr(padded_centroids(:, r), padded_centroids(:, c)));
                end
            end
        end

        dist2 = ip./sqrt(repmat(diag(ip), 1, size(ip,2)) .* repmat(diag(ip)', size(ip,1), 1));
        dist2 = dist2 - eye(length(dist2));                      % remove diagonal, which should be 1
        dist2 = dist2 + sqrt(diag(diag(ip))/size(all_centroids, 1)); % add waveform RMS
        result = dist2;
        titlestr = "Maximum reflective correlation coefficients for all possible waveform time shifts" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = false; % lighter values are *higher* correlation coefficients, which are worse
    elseif isequal(params.clustering.similarity_method, "shiftdist")
        % this method gets the shortest distance between all possible shifts of
        % waveforms with one another, e.g. it gets the max value of the
        % xcorr between them.
        ip = zeros(true_num_cells);
        for r=1:true_num_cells
            for c=r:true_num_cells
                if r == c
                    ip(r, r) = norm(padded_centroids(:, r))^2;
                else
                    ip(r, c) = max(xcorr(padded_centroids(:, r), padded_centroids(:, c)));
                    ip(c, r) = max(xcorr(padded_centroids(:, r), padded_centroids(:, c)));
                end
            end
        end

        dist2 = repmat(diag(ip), 1, size(ip,2)) ...
        - 2*ip ...
        + repmat(diag(ip)', size(ip,1), 1) ...
        + diag(diag(ip));
        result = sqrt(dist2/size(all_centroids,1));
        titlestr = "Minimum RMS distances between all possible waveform time shifts" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = true; % lighter values are shorter distances, which are worse
    elseif isequal(params.clustering.similarity_method, "magspectrum")
        % this method gets the distance between magnitude spectra,
        % which is shift-invariant.

        % padding the centroids pre-fft prevents time-aliasing
        m_centroids = abs(fft(padded_centroids))/sqrt(size(padded_centroids,1));
        ip = m_centroids'*m_centroids;

        dist2 = repmat(diag(ip), 1, size(ip,2)) ...
                - 2*ip ...
                + repmat(diag(ip)', size(ip,1), 1) ...
                + diag(diag(ip));
        result = sqrt(dist2/size(all_centroids,1));
        titlestr = "RMS distances between magnitude spectra" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = true; % lighter values are shorter distances, which are worse
    elseif isequal(params.clustering.similarity_method, "simple")
        % this method simply takes the distance between two waveforms
        % without any time-shifting compensation. This method may not
        % realize when two waveforms are time-shifted versions of one
        % another.
        ip = all_centroids'*all_centroids;

        %%@ the formula below is simply:
        %%@    ||a-b||^2 = <a-b, a-b> = <a,a> - 2<a,b> + <b,b>
        %%@ this makes the diagonal zero, so we then change the diagonal back
        %%@ to <a,a>, and then scale everything so we have an RMS
        %%@ note that the norm of the magnitude spectrum is the same as the
        %%@ norm of the original waveform
        dist2 = repmat(diag(ip), 1, size(ip,2)) ...
                - 2*ip ...
                + repmat(diag(ip)', size(ip,1), 1) ...
                + diag(diag(ip));
        result = sqrt(dist2/size(all_centroids,1));
        titlestr = "Simple, non-time-shifted RMS distances between waveforms" + newline + ...
                   "(Diagonal is RMS-scaled 2-norm)";
        flipmap = true; % lighter values are shorter distances, which are worse
    end

    % now display and plot. Make there be no diagonal for the imagesc
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
    imagesc(result_no_diag);

    % set axes, colormap, labels etc
    axis equal;
    axis tight;
    xlabel('Waveform ID');
    ylabel('Waveform ID');
    title(titlestr);

    % add colorbar, which should be mostly gray but switch to red for the
    % worst offenders
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

    % add text
    for x=1:true_num_cells
        for y=1:true_num_cells
            if x == y
                textcolor = [1.0 1.0 0.0];
            else
                textcolor = [0.0 1.0 1.0];
            end
            text(x, y, num2str(result(x, y), '%5.3f'), ...
              'HorizontalAlignment', 'center', ...
              'Color', textcolor, ...
              'FontWeight', 'bold');
        end
    end

    adjustbutton = popupmenu(t2, menu_params{:});

%% -------------------------------------------------------------------------
% Plot Refined Waveforms (Tab 3)
    t3 = CreateCalibrationTab('Waveform Refinement, Waveforms', 'WaveformRefinement');
    nc = ceil(sqrt(num_plot_cells));
    nr = ceil(num_plot_cells / nc);

    t_axis = (1:size(CBPdata.waveform_refinement.final_waveforms{1},1))*dt*1000;

    % go through the motions once, just to get the axis limits
    max_xlim = [min(t_axis) max(t_axis)];
    max_ylim = [Inf -Inf];
    for n = 1:num_plot_cells
        cur_cell = plot_cells(n);
        cur_init = find(init_assignment_mtx(:, cur_cell));

        % get the average of all the inits that this final is assigned to,
        % or the zero vector if no such inits
        init_waveform = ...
            AveragedWaveform(cur_init, ...
                             CBPdata.CBP.init_waveforms, ...
                             CBPdata.CBP.spike_time_array);
        final_waveform = ...
            reshape(CBPdata.waveform_refinement.final_waveforms{cur_cell}, [], nchan);

        tmp_ylim = [min([init_waveform(:);final_waveform(:)]) max([init_waveform(:);final_waveform(:)])];
        max_ylim(1) = min(tmp_ylim(1), max_ylim(1));
        max_ylim(2) = max(tmp_ylim(2), max_ylim(2));
    end

    % now plot each cell for real
    for n = 1:num_plot_cells
        cur_cell = plot_cells(n);
        cur_init = find(init_assignment_mtx(:, cur_cell));
        cur_cluster = find(cluster_assignment_mtx(:, cur_cell));
        subplot(nr, nc, n);
        cla;

        % get the average of all the inits that this final is assigned to,
        % or the zero vector if no such inits
        init_waveform = ...
            AveragedWaveform(cur_init, ...
                             CBPdata.CBP.init_waveforms, ...
                             CBPdata.CBP.spike_time_array);
        final_waveform = ...
            reshape(CBPdata.waveform_refinement.final_waveforms{cur_cell}, [], nchan);

        % get individual channels, add as separate plots. number of cols is
        % number of channels
        plots = {};

        for m = 1:size(final_waveform,2)
            if m ~= 1
                legendargs = {'HandleVisibility', 'off'};
            else
                legendargs = {};
            end

            % initial waveforms
            plots{end+1} = [];
            plots{end}.x = t_axis;
            plots{end}.y = init_waveform(:,m);
            plots{end}.args = {'Color', 'black', 'DisplayName', 'Initial'};
            plots{end}.args = {plots{end}.args{:} legendargs{:}};
            plots{end}.chan = m;
            plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};

            % final waveforms
            plots{end+1} = [];
            plots{end}.x = t_axis;
            plots{end}.y = final_waveform(:,m);
            plots{end}.args = {'Color', params.plotting.cell_color(cur_cell), 'DisplayName', 'New'};
            plots{end}.args = {plots{end}.args{:} legendargs{:}};
            plots{end}.chan = m;
            plots{end}.axisargs = {'XLim', max_xlim, 'YLim', max_ylim};
        end

        multiplot(plots);

        multiplotxlabel('Time (msec)');
        multiplotlegend('FontSize', 10);

        % Just a note because this is confusing:
        %
        % We are plotting the init_waveform that we got from
        % init_assignment_mtx, which is ultimately derived from
        % CBPdata.CBP.init_waveforms.
        %
        % But, the *title* of the axis plot is the original *cluster* id,
        % which is written as "Orig #n", where n is from the
        % cluster_assignment_mtx.
        %
        % This is because CBPdata.CBP.init_waveforms is the set of
        % waveforms that we *seeded* the CBP algorithm with. So, for the
        % first iteration, it's equal to the clustering waveforms. For
        % the second iteration, it's equal to the waveform_refinement
        % final_waveforms from the previous iteration, and so on.
        %
        % We want to plot, visually, the difference between this waveform
        % and the waveform from the previous iteration, *not* the
        % clustering waveform (aka iteration 1).
        %
        % But, we *do* want the original cluster to be written, at least
        % tangentially, in the title, for reference.
        %
        % So that's why it looks like we're mixing two different things
        % - but we aren't.

        err = norm(init_waveform - final_waveform, 'fro') / ...
                norm(CBPdata.waveform_refinement.final_waveforms{cur_cell}, 'fro');
        if isempty(cur_cluster)         %if this is an "unassigned" cluster
            orig_cluster_id = "N/A";
        else
            % cur_cluster(:)' makes sure it's a row vector
            orig_cluster_id = strjoin(string(cur_cluster(:)'), ', ');
        end
        num_spikes = length(CBPdata.waveform_refinement.spike_time_array_thresholded{cur_cell});
        multiplottitle(sprintf('Cell %d (Orig %s), %d spks, Chg=%.0f%%', ...
                               cur_cell, orig_cluster_id, num_spikes, 100*err));

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

%%@ FIXME - catch catches too many errors. should add ID in assertion
function splitCallback(varargin)
    global CBPdata params;
    dlgtext = inputdlg(['Enter waveform ID to split (1-' num2str(CBPdata.waveform_refinement.num_waveforms) '):'], ...
                        'Split CBP Waveforms');

    if ~isempty(dlgtext)
        to_split = str2num(strtrim(dlgtext{1}));

        dlgtext2 = inputdlg('Enter number of new waveforms to split into:', 'Split CBP Waveforms');
        num_splits = str2num(dlgtext2{1});

        SplitCBPWaveform(to_split, num_splits);
    end
end

function mergeCallback(varargin)
    global CBPdata params;
    dlgtext = inputdlg(['Enter list of waveform IDs to merge (1-' num2str(CBPdata.waveform_refinement.num_waveforms) '), ' ...
                        'separated by space:'], ...
                        'Merge CBP Waveforms');

    if ~isempty(dlgtext)
        to_merge = dlgtext{1};
        to_merge = strrep(to_merge,',',' ');    %just in case they put commas
        to_merge = strsplit(strtrim(to_merge), ' ');
        to_merge = cellfun(@str2num, to_merge);

        MergeCBPWaveforms(to_merge);
    end
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
                        'Reassess CBP Waveforms');

    if ~isempty(dlgtext)
        to_reassess = dlgtext{1};
        to_reassess = strrep(to_reassess,',',' ');    %just in case they put commas
        to_reassess = strsplit(strtrim(to_reassess), ' ');
        to_reassess = cellfun(@str2num,to_reassess);

        ReassessCBPWaveforms(to_reassess);
    end
end

function addCallback(varargin)
    global params;
    dlgtext = inputdlg(['This method "adds" a new waveform to the set of existing ' ...
                        'waveforms by removing *all* estimated waveforms ' ...
                        'from the signal, and then clustering the residue ' ...
                        'to produce a new set of waveforms that are added to ' ...
                        'the existing set of waveforms.' newline ...
                          newline ...
                        'Enter number of new waveforms to add:'], ...
                        'Add New Waveforms');

    if ~isempty(dlgtext) && ~isempty(dlgtext{1})
        to_add = dlgtext{1};
        to_add = strrep(to_add,',',' ');    %just in case they put commas
        to_add = strsplit(strtrim(to_add), ' ');
        to_add = cellfun(@str2num,to_add);

        AddCBPWaveforms(to_add);
    end
end

function removeCallback(varargin)
    global params;
    dlgtext = inputdlg(['This method "removes" a set of waveforms from the existing ' ...
                        'set by simply dropping that waveform without splitting ' ...
                        'or merging anything else.' ...
                        newline ...
                        'Enter waveform IDs to remove:'], ...
                        'Remove CBP Waveforms');

    if ~isempty(dlgtext)
        to_remove = dlgtext{1};
        to_remove = strrep(to_remove,',',' ');    %just in case they put commas
        to_remove = strsplit(strtrim(to_remove), ' ');
        to_remove = cellfun(@str2num,to_remove);

        RemoveCBPWaveforms(to_remove);
    end
end
