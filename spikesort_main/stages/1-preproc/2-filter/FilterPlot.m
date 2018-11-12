function FilterPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Filtered Data, Amplitudes');
        return;
    end

    filtering = dataobj.filtering;

% -------------------------------------------------------------------------
% Set up basics
    % local variables to reuse
    data = filtering.data;
    dataMag = sqrt(sum(data.^2, 1));    %%@ Again hard-coded RMS

    nchan = size(data,1);
    thresh = params.whitening.noise_threshold;

    minZoneLen = params.whitening.min_zone_len;
    if isempty(minZoneLen)
        minZoneLen = params.rawdata.waveform_len/2;
    end

    noiseZones = GetNoiseZones(dataMag, thresh, minZoneLen);
    noiseZoneInds = cell2mat(cellfun(@(c) c', noiseZones, 'UniformOutput', false));
    zonesL = cellfun(@(c) c(1), noiseZones);
    zonesR = cellfun(@(c) c(end), noiseZones);

% -------------------------------------------------------------------------
% Plot Time Domain (top-left subplot)
    t_filt = CreateCalibrationTab('Filtered Data, Amplitudes', 'Filter');

    subplot(2,2,1);
    cla;

    %get channel offsets
    plotChannelOffset = 2*(mean(data(:).^6)).^(1/6)*ones(filtering.nsamples,1)*([1:nchan]-1);
    plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));
    mxOffset = plotChannelOffset(1,end);

    %draw red polygon behind noise segments
    noiseCol = [1 0.4 0.4];
    nh=patch(filtering.dt*[[1;1]*zonesL; [1;1]*zonesR],...
         (mxOffset+thresh)*[-1;1;1;-1]*ones(1,length(zonesL)), noiseCol,...
         'EdgeColor', noiseCol);

    %plot zero-crossing
    hold on;
    plot([0 (filtering.nsamples-1)*filtering.dt], [0 0], 'k');

    %plot channels
    plot((0:filtering.nsamples-1)*filtering.dt, filtering.data' + plotChannelOffset);
    hold off;

    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    legend('Noise regions (to be whitened)');
    xlabel('Time (sec)');
    ylabel('Filtered signal');
    title('Filtered data');

% -------------------------------------------------------------------------
% Plot Frequency Domain (bottom-left subplot)
    subplot(2,2,3);
    cla;
    maxDFTind = floor(filtering.nsamples/2);
    dftMag = abs(fft(filtering.data,[],2));
    if (nchan > 1.5)
        dftMag = sqrt(sum(dftMag.^2)); %%@ MUST CHANGE THIS TOO
    end
    plot(([1:maxDFTind]-1)/(maxDFTind*filtering.dt*2), dftMag(1:maxDFTind));
    set(gca,'Yscale','log'); axis tight;
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title('Fourier amplitude, filtered data');

% -------------------------------------------------------------------------
% Plot Filtered Data Histogram (top-right subplot)
    subplot(2,2,2); cla;

    sd = sqrt(sum(cellfun(@(c) sum(dataMag(c).^2), noiseZones)) / ...
              (nchan*sum(cellfun(@(c) length(c), noiseZones))));
    mx = max(abs(filtering.data(:)));
    nbins = min(100, 2*size(filtering.data,2)^(1/3)); % Rice rule for histogram binsizes
    % nbins = size(datain.data,2)^(1/3) / (2*iqr(datain.data(:))); % Freedman–Diaconis rule for histogram binsize
    X=linspace(-mx,mx,nbins);
    N=hist(filtering.data',X);

    plot(X,N);
    set(gca,'Yscale','log');
    rg=get(gca,'Ylim');
    rg(2) = rg(2)*10; %%@Mike's change - leave extra room for legend

    hold on;
    gh=plot(X, max(N(:))*exp(-(X.^2)/(2*sd.^2)), 'r', 'LineWidth', 2);
    %%@Mike's comment - the below was there. why do we plot(X,N) twice?
    %%@Just screws up the color
    %%@plot(X,N);
    set(gca,'Ylim',rg);
    hold off;

    if (nchan < 1.5)
      title('Histogram, filtered data');
    else
      title(sprintf('Histograms, filtered data (%d channels)', nchan));
    end
    xlabel('Filtered signal')
    legend('Filtered data (combined channels)', 'Gaussian, fit to noise regions');

% -------------------------------------------------------------------------
% Plot Cross-Channel Histogram (bottom-right subplot)

    subplot(2,2,4); cla;

    [N,X] = hist(dataMag, nbins);
    [Nnoise] = hist(dataMag(noiseZoneInds), X);
    chi = 2*(X/sd).*chi2pdf((X/sd).^2, nchan);
    h=bar(X,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    dh= bar(X,Nnoise); set(dh, 'FaceColor', noiseCol, 'BarWidth', 1);
    ch= plot(X, (max(N)/max(chi))*chi, 'k', 'LineWidth', 2);
    hold off; set(gca, 'Ylim', yrg);
    xlabel('RMS magnitude (over all channels)');
    legend([h,dh, ch], 'Filtered data (combined channels)', 'Noise regions', 'Chi-distribution, fit to noise regions');
    title('Histogram, cross-channel magnitude of filtered data');
end
