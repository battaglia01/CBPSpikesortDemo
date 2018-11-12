function MikeComparisonPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Mike Comparison');
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
    CreateCalibrationTab('Mike Comparison', 'MikeComparison');

    %calculate offsets
    plotChannelOffset = 2*(mean(whitening.data(:).^6)).^(1/6)*ones(whitening.nsamples,1)*([1:nchan]-1);
    plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));

    gca;
    hold all;
    plot((0:whitening.nsamples-1)*whitening.dt, whitening.data' + plotChannelOffset);
    
    yrg = get(gca,'Ylim');
    xrg = get(gca,'Xlim');
    
    bandHt = 0.12;
    yinc = bandHt*(yrg(2)-yrg(1))/length(init_waveforms);
    clrs = hsv(length(init_waveforms)); %%@ color darkening

    patch([0;(whitening.nsamples-1)*whitening.dt; ...
        (whitening.nsamples-1)*whitening.dt; 0], ...
        [yrg(2)*[1;1]; (yrg(1)+(1+bandHt)*(yrg(2)-yrg(1)))*[1;1]], ...
          0.9*[1 1 1], 'EdgeColor', 0.9*[1 1 1]);

    set(gca,'Ylim', [yrg(1), yrg(2)+bandHt*(yrg(2)-yrg(1))]);

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
    xlabel('Time (sec)');
    title('Recovered spikes');
