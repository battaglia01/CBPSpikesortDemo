function SpikeTimingPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DisableCalibrationTab('CBP Results');
        return;
    end

% -------------------------------------------------------------------------
% Set up basics
    %set up local vars to reuse
    whitening = dataobj.whitening;
    spike_times = dataobj.CBPinfo.spike_times;
    spike_amps = dataobj.CBPinfo.spike_amps;
    spike_traces_init = dataobj.CBPinfo.spike_traces_init;
    init_waveforms = dataobj.CBPinfo.init_waveforms;
    snippets = dataobj.CBPinfo.snippets;
    recon_snippets = dataobj.CBPinfo.recon_snippets;
    nchan = size(whitening.data,1);

% -------------------------------------------------------------------------
% Plot Timeseries data (top-left subplot)
    AddCalibrationTab('CBP Results');
    subplot(2,2,1);
    cla;

    %create combined spike trace waveform to subtract from whitening data
    combined_spike_traces = zeros(size(whitening.data'));
    for n=1:length(spike_traces_init)
        combined_spike_traces = combined_spike_traces + spike_traces_init{n};
    end
    
    %residual_noise = whitening.data' - combined_spike_traces;
    residual_noise = whitening.data';       %%@disable difference
    
    plotChannelOffset = 6*ones(whitening.nsamples,1)*([1:nchan]-1); %**magic number

    plot((0:whitening.nsamples-1)*whitening.dt, residual_noise + plotChannelOffset, 'k');

    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    xlabel('time (sec)');
    title(sprintf('Data, filtered & whitened, nChannels=%d, %.1fkHz', nchan, 1/(1000*whitening.dt)));

% -------------------------------------------------------------------------
% Plot recovered spikes (bottom-left subplot)

    yrg = get(gca,'Ylim');
    xrg = get(gca,'Xlim');

    subplot(2,2,3);
    cla;

    bandHt = 0.12;
    yinc = bandHt*(yrg(2)-yrg(1))/length(init_waveforms);
    clrs = hsv(length(init_waveforms)); %%@ color darkening

    patch([0;(whitening.nsamples-1)*whitening.dt; ...
        (whitening.nsamples-1)*whitening.dt; 0], ...
        [yrg(2)*[1;1]; (yrg(1)+(1+bandHt)*(yrg(2)-yrg(1)))*[1;1]], ...
          0.9*[1 1 1], 'EdgeColor', 0.9*[1 1 1]);

    set(gca,'Ylim', [yrg(1), yrg(2)+bandHt*(yrg(2)-yrg(1))]);
    hold on

    %** Should do proper interpolation
    %%@ Mike note - windowed sinc interpolation?
    for n=1:length(spike_traces_init)
        %plot top
        plot((spike_times{n}-1)*whitening.dt, (yrg(2)+(n-0.5)*yinc)*ones(1,length(spike_times{n})), '.', 'Color', clrs(n,:));
        
        %plot waveform
        plot((0:whitening.nsamples-1)*whitening.dt, spike_traces_init{n} + plotChannelOffset, 'Color', clrs(n,:));
    end

    %plot zero-crossing
    plot((0:whitening.nsamples-1)*whitening.dt, plotChannelOffset, 'k');
    hold off;

    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    xlabel('time (sec)');
    title('Recovered spikes');

% -------------------------------------------------------------------------
% Plot Residual Histograms (top-right subplot)
    subplot(2,2,2);
    cla;
    resid = cell2mat(cellfun(@(c,cr) c-cr, snippets, recon_snippets, 'UniformOutput', false));
    %mx = max(cellfun(@(c) max(abs(c(:))), snippets));
    mx = max(abs(whitening.data(:)));       %%@Linf -- is this right?
    [N, Xax] = hist(resid, mx*[-50:50]/101);
    plot(Xax,N); set(gca,'Yscale','log'); rg=get(gca,'Ylim');
    hold on
    gh=plot(Xax, max(N(:))*exp(-(Xax.^2)/2), 'r', 'LineWidth', 2);
    plot(Xax,N); set(gca,'Ylim',rg); set(gca, 'Xlim', [-mx mx]);
    hold off;
    if (nchan < 1.5)
        title('Histogram, spikes removed');
    else
        title(sprintf('Histograms, spikes removed (%d channels)', nchan));
    end
    legend(gh, 'univariate Gaussian');

% -------------------------------------------------------------------------
% Plot Histogram of magnitude (bottom-right subplot)
    %Histogram of magnitude
    subplot(2,2,4); cla;
    mx = max(sqrt(sum(whitening.data.^2,1)));
    [N,Xax] = hist(sqrt(sum(resid.^2, 2)), mx*[0:100]/100);
    chi = 2*Xax.*chi2pdf(Xax.^2, nchan);
    bar(Xax,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    ch= plot(Xax, (max(N)/max(chi))*chi, 'r', 'LineWidth', 2);
    hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
    title('Histogram, magnitude with spikes removed');
    legend(ch, 'chi-distribution, univariate Gaussian');

    %   Fig6: projection into PC space of segments, with spike assignments (as in paper)
