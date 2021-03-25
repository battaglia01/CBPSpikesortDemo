% Calibration for CBP results:
% Fig1: visually compare whitened data, recovered spikes
% Fig2: residual histograms (raw and cross-channel magnitudes) - compare to Fig3

function SpikeTimingPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('CBP Waveforms, PCs');
        DeleteCalibrationTab('CBP Results');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    %set up local vars to reuse
    whitening = CBPdata.whitening;
    spike_time_array = CBPdata.CBP.spike_time_array;
    spike_amps = CBPdata.CBP.spike_amps;
    spike_traces_init = CBPdata.CBP.spike_traces_init;
    init_waveforms = CBPdata.CBP.init_waveforms;
    snippets = CBPdata.CBP.snippets;
    recon_snippets = CBPdata.CBP.recon_snippets;
    nchan = size(whitening.data,1);

    % get the cells to plot. This is whatever cells are listed as being
    % plottable in plot_cells, intersected with the total number of cells.
    true_num_cells = CBPdata.CBP.num_waveforms;
    plot_cells = intersect(CBPInternals.cells_to_plot, 1:true_num_cells);
    num_cells = length(plot_cells);
    CheckPlotCells(num_cells);
    
% =========================================================================
% TAB 1
% -------------------------------------------------------------------------
% Plot Timeseries data (top-left subplot)
    CreateCalibrationTab('CBP Waveforms, PCs', 'SpikeTiming');
    cla('reset');
    PlotPCA(CBPdata.CBP.X, CBPdata.CBP.XProj, CBPdata.CBP.assignments, ...
            CBPdata.CBP.num_waveforms);
    title(sprintf('CBP waveforms (%d spike types, %d plotted)', ...
                  true_num_cells, num_cells));

% =========================================================================
% TAB 2
% -------------------------------------------------------------------------
% Plot Timeseries data (top-left subplot)
    CreateCalibrationTab('CBP Results', 'SpikeTiming');
    subplot(2,2,1);
    cla;

    plots = {};
    for n=1:size(whitening.data,1)
        plots{end+1} = [];
        plots{end}.dt = whitening.dt;
        plots{end}.y = whitening.data(n,:)';
        plots{end}.args = {'HandleVisibility', 'off'};
    end
    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);

    multiplotxlabel('Time (sec)');
    multiplotylabel('Whitened signal (z-scored)');
    multiplottitle(sprintf('Data, filtered & whitened, nChannels=%d, %.1fkHz', nchan, 1/(1000*whitening.dt)));

% -------------------------------------------------------------------------
% Plot recovered spikes (bottom-left subplot)

    ax = getappdata(getappdata(gca,'panel'),'mp_axes');

    yrg = get(ax(1),'Ylim');
    xrg = get(ax(1),'Xlim');

    subplot(2,2,3);
    cla;

    %** Should do proper interpolation
    %%@ Mike note - windowed sinc interpolation?

    plots = {};
    % Add spike traces to plot
    for n=1:num_cells
        c = plot_cells(n);
        for m=1:size(spike_traces_init{c},2)
            plots{end+1} = [];
            plots{end}.dt = whitening.dt;
            plots{end}.y = spike_traces_init{c}(:,m);
            plots{end}.args = {'HandleVisibility', 'off', ...
                               'Color', params.plotting.cell_color(c)};
            plots{end}.chan = m+1;
        end
    end

    % Add zero-crossing to plot
    %%@! OPT - this doesn't need to be so many samples!! Maybe try "rawplot?"
    for n=1:nchan
        plots{end+1} = [];
        plots{end}.dt = whitening.dt;
        plots{end}.y = zeros(whitening.nsamples,1);
        plots{end}.args = {'HandleVisibility', 'off', 'Color', [0 0 0]};
        plots{end}.chan = n+1;
    end

    % Add indicators to plot
    for n=1:num_cells
        c = plot_cells(n);
        vertalign = 1-(n-1)/(num_cells-1);
        plots{end+1} = [];
        plots{end}.x = (spike_time_array{c}-1)*whitening.dt;
        plots{end}.y = vertalign*ones(1,length(spike_time_array{c}));
        plots{end}.args = {'.', 'Color', params.plotting.cell_color(c)};
        plots{end}.chan = 'header';
        plots{end}.type = 'rawplot';
    end

    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);

    % lastly, scale top axis manually
    ax = getappdata(getappdata(gca,'panel'),'mp_axes');
    ylim(ax(1), [-0.5 1.5]);
    multiplotsubignorefunc(@ylim, 1);

    multiplotxlabel('Time (sec)');
    multiplottitle('Recovered spikes');

% -------------------------------------------------------------------------
% Plot Residual Histograms (top-right subplot)
    subplot(2,2,2);
    cla;
    resid = cell2mat(cellfun(@(c,cr) c-cr, snippets, recon_snippets, 'UniformOutput', false));
    %mx = max(cellfun(@(c) max(abs(c(:))), snippets));
    mx = max(abs(whitening.data(:)));       %%@Linf -- is this right?
    [N, Xax] = hist(resid, mx*[-50:50]/101);

    plot(Xax,N);
    set(gca,'Yscale','log');
    rg=get(gca,'Ylim');
    rg(2) = rg(2)*10;

    hold on;
    sigCol = [0 0.8 0];   % NOTE: used to be red
    %%@ RMS vs L2??
    gh=plot(Xax, max(N(:))*exp(-(Xax.^2)/2), 'Color', sigCol, 'LineWidth', 2);

    %%@Would be nice if we could avoid repeated code here - also in
    %%@WhitenPlot, FilterPlot, etc

    set(gca,'Ylim',rg);
    set(gca, 'Xlim', [-mx mx]);
    hold off;

    if (nchan < 1.5)
        title('Histogram, spikes removed');
    else
        title(sprintf('Histograms, spikes removed (%d channels)', nchan));
    end
    xlabel('Whitened signal (z-scored)');
    legend('Whitened data (combined channels)', 'Gaussian, fit to spike-removed data');

% -------------------------------------------------------------------------
% Plot Histogram of magnitude (bottom-right subplot)
    %Histogram of magnitude
    subplot(2,2,4); cla;
    mx = max(sqrt(sum(whitening.data.^2,1)));    %%@ RMS vs L2?
    [N,Xax] = hist(sqrt(sum(resid.^2, 2)), mx*[0:100]/100);
    chi = 2*Xax.*chi2pdf(Xax.^2, nchan);
    bar(Xax,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    ch= plot(Xax, (max(N)/max(chi))*chi, 'r', 'LineWidth', 2);
    hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
    title('Histogram, magnitude with spikes removed');
    legend('Whitened data, spikes removed', 'Chi-distribution, fit to spike-removed data');
    %   Fig6: projection into PC space of segments, with spike assignments (as in paper)
