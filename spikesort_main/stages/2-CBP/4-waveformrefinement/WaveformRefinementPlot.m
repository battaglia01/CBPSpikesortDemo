% Calibration for CBP waveforms:
% If recovered waveforms differ significantly from initial waveforms, then algorithm
% has not yet converged - do another iteration of CBP.

function WaveformRefinementPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command,'disable')
        DeleteCalibrationTab('Waveform Refinement');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    %set up local vars
    true_num_cells = params.clustering.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);

    dt = CBPdata.whitening.dt;
    nchan = size(CBPdata.whitening.data,1);

% -------------------------------------------------------------------------
% Plot PCs (Tab 1)
    CreateCalibrationTab('Waveform Refinement', 'WaveformRefinement');
    nc = ceil(sqrt(num_cells));
    nr = ceil(num_cells / nc);

    t_axis = (1:size(CBPdata.waveformrefinement.final_waveforms{1},1))*dt*1000;

    ylims = zeros(num_cells, 2);
    for n = 1:num_cells
        c = plot_cells(n);
        subplot(nr, nc, n);
        cla;
        inits = reshape(CBPdata.CBP.init_waveforms{c},[],nchan);
        finals = reshape(CBPdata.waveformrefinement.final_waveforms{c},[],nchan);

        % get individual channels, add as separate plots. number of cols is
        % number of channels
        plots = {};
        for m = 1:size(inits,2)
            % initial waveforms
            if m ~= 1
                legendargs = {'HandleVisibility', 'off'};
            else
                legendargs = {};
            end

            plots{end+1} = [];
            plots{end}.x = t_axis;
            plots{end}.y = inits(:,m);
            plots{end}.args = {'Color', 'black', 'DisplayName', 'Initial'};
            plots{end}.args = {plots{end}.args{:} legendargs{:}};
            plots{end}.chan = m;

            % final waveforms
            plots{end+1} = [];
            plots{end}.x = t_axis;
            plots{end}.y = finals(:,m);
            plots{end}.args = {'Color', params.plotting.cell_color(c), 'DisplayName', 'New'};
            plots{end}.args = {plots{end}.args{:} legendargs{:}};
            plots{end}.chan = m;
        end

        multiplot(plots);

        multiplotsubfunc(@xlim, dt*1000*[1, size(CBPdata.waveformrefinement.final_waveforms{1},1)]);
        multiplotxlabel('Time (msec)');
        multiplotlegend('FontSize', 10);

        err = norm(CBPdata.CBP.init_waveforms{c} - ...
            CBPdata.waveformrefinement.final_waveforms{c})/norm(CBPdata.waveformrefinement.final_waveforms{c});
        multiplottitle(sprintf('Cell %d, Change=%.0f%%', c, 100*err));

        ylims(n,:) = [min([inits(:); finals(:)]) max([inits(:); finals(:)])];

        % Due to MATLAB subplot(...) display bug, when we try to switch
        % subplots below, it overwrites the original. As a workaround,
        % just save each subplot axes handle in a cell array and do it
        % manually
        subplotaxes{n} = gca;
    end

    % make axis ticks same size on all subplots
    max_ylim = [min(ylims(:,1)) max(ylims(:,2))];
    for n = 1:num_cells
        % Note above issue with subplot(...) overwrite bug. Do this instead
        % subplot(nc,nr,n); %%@ changed to below, left for reference
        axes(subplotaxes{n});
        multiplotsubfunc(@ylim, max_ylim);
    end
end
