function dataout = PlotFilteredData(datain)
global params dataobj;
% Plot filtered data, Fourier amplitude, and histogram of magnitudes

    data = datain.data;

    % copied from WhitenNoise: %%@ Mike's comment - oh no, duplicated code?!
    %%@ Again hard-coded RMS
    dataMag = sqrt(sum(data .^ 2, 1));
    %dataMag = sum(abs(data),1); %%@  Use Linf
    nchan = size(data,1);
    thresh = params.whitening.noise_threshold;
    minZoneLen = params.whitening.min_zone_len;
    if isempty(minZoneLen), minZoneLen = params.rawdata.waveform_len/2; end
    noiseZones = GetNoiseZones(dataMag, thresh, minZoneLen);
    noiseZoneInds = cell2mat(cellfun(@(c) c', noiseZones, 'UniformOutput', false));
    zonesL = cellfun(@(c) c(1), noiseZones);  zonesR = cellfun(@(c) c(end), noiseZones);

    %Plot time domain
    t_filt = AddCalibrationTab('Filtered Data');

    subplot(2,2,1); cla;

    noiseCol = [1 0.4 0.4];
    inds = params.rawdata.data_plot_inds;
    plotChannelOffset = 2*(mean(data(:).^6)).^(1/6)*ones(length(inds),1)*([1:nchan]-1);
    plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));
    mxOffset = plotChannelOffset(1,end);
    visibleInds = find(((inds(1) < zonesL) & (zonesL < inds(end))) |...
                       ((inds(1) < zonesR) & (zonesR < inds(end))));

    if(~isempty(visibleInds))
        nh=patch(datain.dt*[[1;1]*zonesL(visibleInds); [1;1]*zonesR(visibleInds)],...
             (mxOffset+thresh)*[-1;1;1;-1]*ones(1,length(visibleInds)), noiseCol,...
             'EdgeColor', noiseCol);
    end

    hold on;
    plot([inds(1), inds(end)]*datain.dt, [0 0], 'k');
    dh = plot((inds-1)*datain.dt, datain.data(:,inds)' + plotChannelOffset);
    hold off;

    set(gca, 'Xlim', ([inds(1),inds(end)]-1)*datain.dt);
    %  set(gca,'Ylim',[-1 1]);
    legend('noise regions (to be whitened)');  title('Filtered data');

    %Plot frequency domain

    subplot(2,2,2); cla;
    maxDFTind = floor(datain.nsamples/2);
    dftMag = abs(fft(datain.data,[],2));
    if (nchan > 1.5)
        dftMag = sqrt(sum(dftMag.^2)); %%@ MUST CHANGE THIS TOO
    end;
    plot(([1:maxDFTind]-1)/(maxDFTind*datain.dt*2), dftMag(1:maxDFTind));
    set(gca,'Yscale','log'); axis tight;
    xlabel('frequency (Hz)'); ylabel('amplitude');
    title('Fourier amplitude, filtered data');

    %Plot histogram
    subplot(2,2,3); cla;

    sd = sqrt(sum(cellfun(@(c) sum(dataMag(c).^2), noiseZones)) / ...
              (nchan*sum(cellfun(@(c) length(c), noiseZones))));
    mx = max(abs(datain.data(:)));
    nbins = min(100, 2*size(datain.data,2)^(1/3)); % Rice rule for histogram binsizes
    % nbins = size(datain.data,2)^(1/3) / (2*iqr(datain.data(:))); % Freedman–Diaconis rule for histogram binsize
    X=linspace(-mx,mx,nbins);
    N=hist(datain.data',X);

    plot(X,N); set(gca,'Yscale','log'); rg=get(gca,'Ylim');
    hold on;
    gh=plot(X, max(N(:))*exp(-(X.^2)/(2*sd.^2)), 'r', 'LineWidth', 2);
    plot(X,N); set(gca,'Ylim',rg);
    hold off;

    if (nchan < 1.5)
      title('Histogram, filtered data');
    else
      title(sprintf('Histograms, filtered data (%d channels)', nchan));
    end
    legend('Data', 'Gaussian, fit to noise regions');


    subplot(2,2,4); cla;

    [N,X] = hist(dataMag, nbins);
    [Nnoise] = hist(dataMag(noiseZoneInds), X);
    chi = 2*(X/sd).*chi2pdf((X/sd).^2, nchan);
    h=bar(X,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    dh= bar(X,Nnoise); set(dh, 'FaceColor', noiseCol, 'BarWidth', 1);
    ch= plot(X, (max(N)/max(chi))*chi, 'g');
    hold off; set(gca, 'Ylim', yrg);
    xlabel('rms magnitude (over all channels)');
    legend([h,dh, ch], 'all data', 'noise regions', 'chi-distribution, fit to noise regions');
    title('Histogram, cross-channel magnitude of filtered data');
end
