<<<<<<< HEAD
function PlotWhitenedData(datain)
global params dataobj;

gen_pars = params.general;
data_whitened = datain.data;

old_acfs = datain.old_acfs;
whitened_acfs = datain.whitened_acfs;
old_cov = datain.old_cov;
whitened_cov = datain.whitened_cov;

% Visualization of noise zone estimation
dt = datain.dt;
font_size = 12;
nchan = size(data_whitened, 1);

% Visualization of whitening effects
AddCalibrationTab('Whitened Data, auto-corr');
    nr = ceil(sqrt(nchan));
    tax = (0 : dt : (length(old_acfs{1}) - 1) * dt)' .* 1e3;
    for chan = 1 : nchan
        subplot(nr, nr, chan); cla;
        plot(tax, [old_acfs{chan}, whitened_acfs{chan}], ...
              '.-', 'LineWidth', 1, 'MarkerSize', 14);
        set(gca, 'FontSize', font_size);
        xlabel('time lag (ms)');
        ylabel('autocorrelation');
        legend('original', 'whitened');
        hold on; plot([tax(1), tax(end)], [0 0], 'k-');
        title(sprintf('Channel %d', chan));
    end
    if (nchan > 1.5)
      AddCalibrationTab('Whitened Data, x-corr');
      subplot(1, 2, 1); cla; imagesc(old_cov);
      colormap(gray); axis equal; axis tight;
      set(gca, 'FontSize', font_size);
      title('Orig. cross-channel covariance');
      xlabel('channel');    ylabel('channel');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
      subplot(1, 2, 2); cla; imagesc(whitened_cov);
      colormap(gray); axis equal; axis tight;
      set(gca, 'FontSize', font_size);
      xlabel('channel');
      title('Whitened cross-channel covariance');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
    end

% visualization of whitened data, FFT, and histograms
    inds = params.rawdata.data_plot_inds;
    % copied from preproc/EstimateInitialWaveforms.m:
    dataMag = sqrt(sum(datain.data .^ 2, 1));
    thresh = params.clustering.spike_threshold;
    peakInds = dataMag(inds)> thresh;
    peakLen = params.clustering.peak_len;
    if (isempty(peakLen)), peakLen=floor(params.rawdata.waveform_len/2); end;
    for i = -peakLen : peakLen
        peakInds = peakInds & dataMag(inds) >= dataMag(inds+i);
    end
    peakInds = inds(peakInds);

    %Go back over the Time domain tab
    AddCalibrationTab('Whitened Data, roundup');
    subplot(2,2,1); cla;
    sigCol = [0.4 1 0.5];

    %Copied from PlotFilteredData
    plotChannelOffset = 2*(mean(datain.data(:).^6)).^(1/6)*ones(length(inds),1)*([1:nchan]-1);
    plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));
    mxOffset = plotChannelOffset(1,end);

    hold on;
    sh = patch(datain.dt*[[1;1]*(peakInds-peakLen); [1;1]*(peakInds+peakLen)], ...
          (mxOffset+thresh)*[-1;1;1;-1]*ones(1,length(peakInds)), sigCol,'EdgeColor',sigCol);
    plot((inds-1)*datain.dt, datain.data(:,inds)'+plotChannelOffset);
    hold off
    axis tight
    title('Filtered & noise-whitened data')
    legend('putative spike segments (for initial waveform estimation)');

    %Go back over the Frequency domain tab
    GetCalibrationTab('Frequency Domain');
    subplot(2,2,2); cla;
    maxDFTind = floor(datain.nsamples/2);
    dftMag = abs(fft(datain.data,[],2));
    if (nchan > 1.5), dftMag = sqrt(mean(dftMag.^2)); end;
    plot(([1:maxDFTind]-1)/(maxDFTind*datain.dt*2), dftMag(1:maxDFTind));
    set(gca, 'Yscale', 'log'); axis tight;
    xlabel('frequency (Hz)'); ylabel('amplitude');
    title('Fourier amplitude, filtered & noise-whitened data');

    %Add to Histograms
    GetCalibrationTab('Data Histograms');
    subplot(2,2,3); cla;
    mx = max(abs(datain.data(:)));
    [N, X] = hist(datain.data',100);
    plot(X,N); set(gca,'Yscale','log'); rg=get(gca,'Ylim');
    hold on;
    gh=plot(X, max(N(:))*exp(-(X.^2)/2), 'r', 'LineWidth', 2);
    plot(X,N); set(gca,'Ylim',rg); set(gca, 'Xlim', [-mx mx]);
    hold off;
    if (nchan < 1.5)
      title('Histogram, filtered/whitened data');
    else
      title(sprintf('Histograms, filtered/whitened data, %d channels', nchan));
    end
    legend(gh, 'univariate Gaussian');

    subplot(2,2,4); cla;
    mx = max(dataMag);
    [N,X] = hist(dataMag, 100);
    Nspikes = hist(dataMag(dataMag>thresh), X);
    chi = 2*X.*chi2pdf(X.^2, nchan);
    bar(X,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    dh= bar(X,Nspikes); set(dh, 'FaceColor', sigCol);
    ch= plot(X, (max(N)/max(chi))*chi, 'r', 'LineWidth', 2);
    hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
    title('Histogram, magnitude over filtered/whitened channel(s)');
    legend([dh, ch], 'putative spike segments', 'chi-distribution, univariate Gaussian');
=======
function PlotWhitenedData(datain)
global params dataobj;

gen_pars = params.general;
data_whitened = datain.data;

old_acfs = datain.old_acfs;
whitened_acfs = datain.whitened_acfs;
old_cov = datain.old_cov;
whitened_cov = datain.whitened_cov;

% Visualization of noise zone estimation
dt = datain.dt;
font_size = 12;
nchan = size(data_whitened, 1);

% Visualization of whitening effects
AddCalibrationTab('Whitened Data, auto-corr');
    nr = ceil(sqrt(nchan));
    tax = (0 : dt : (length(old_acfs{1}) - 1) * dt)' .* 1e3;
    for chan = 1 : nchan
        subplot(nr, nr, chan); cla;
        plot(tax, [old_acfs{chan}, whitened_acfs{chan}], ...
              '.-', 'LineWidth', 1, 'MarkerSize', 14);
        set(gca, 'FontSize', font_size);
        xlabel('time lag (ms)');
        ylabel('autocorrelation');
        legend('original', 'whitened');
        hold on; plot([tax(1), tax(end)], [0 0], 'k-');
        title(sprintf('Channel %d', chan));
    end
    if (nchan > 1.5)
      AddCalibrationTab('Whitened Data, x-corr');
      subplot(1, 2, 1); cla; imagesc(old_cov);
      colormap(gray); axis equal; axis tight;
      set(gca, 'FontSize', font_size);
      title('Orig. cross-channel covariance');
      xlabel('channel');    ylabel('channel');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
      subplot(1, 2, 2); cla; imagesc(whitened_cov);
      colormap(gray); axis equal; axis tight;
      set(gca, 'FontSize', font_size);
      xlabel('channel');
      title('Whitened cross-channel covariance');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
    end

% visualization of whitened data, FFT, and histograms
    inds = params.rawdata.data_plot_inds;
    % copied from preproc/EstimateInitialWaveforms.m:
    dataMag = sqrt(sum(datain.data .^ 2, 1));
    thresh = params.clustering.spike_threshold;
    peakInds = dataMag(inds)> thresh;
    peakLen = params.clustering.peak_len;
    if (isempty(peakLen)), peakLen=floor(params.rawdata.waveform_len/2); end;
    for i = -peakLen : peakLen
        peakInds = peakInds & dataMag(inds) >= dataMag(inds+i);
    end
    peakInds = inds(peakInds);

    %Go back over the Time domain tab
    AddCalibrationTab('Whitened Data, roundup');
    subplot(2,2,1); cla;
    sigCol = [0.4 1 0.5];

    %Copied from PlotFilteredData
    plotChannelOffset = 2*(mean(datain.data(:).^6)).^(1/6)*ones(length(inds),1)*([1:nchan]-1);
    plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));
    mxOffset = plotChannelOffset(1,end);

    hold on;
    sh = patch(datain.dt*[[1;1]*(peakInds-peakLen); [1;1]*(peakInds+peakLen)], ...
          (mxOffset+thresh)*[-1;1;1;-1]*ones(1,length(peakInds)), sigCol,'EdgeColor',sigCol);
    plot((inds-1)*datain.dt, datain.data(:,inds)'+plotChannelOffset);
    hold off
    axis tight
    title('Filtered & noise-whitened data')
    legend('putative spike segments (for initial waveform estimation)');

    %Go back over the Frequency domain tab
    GetCalibrationTab('Frequency Domain');
    subplot(2,2,2); cla;
    maxDFTind = floor(datain.nsamples/2);
    dftMag = abs(fft(datain.data,[],2));
    if (nchan > 1.5), dftMag = sqrt(mean(dftMag.^2)); end;
    plot(([1:maxDFTind]-1)/(maxDFTind*datain.dt*2), dftMag(1:maxDFTind));
    set(gca, 'Yscale', 'log'); axis tight;
    xlabel('frequency (Hz)'); ylabel('amplitude');
    title('Fourier amplitude, filtered & noise-whitened data');

    %Add to Histograms
    GetCalibrationTab('Data Histograms');
    subplot(2,2,3); cla;
    mx = max(abs(datain.data(:)));
    [N, X] = hist(datain.data',100);
    plot(X,N); set(gca,'Yscale','log'); rg=get(gca,'Ylim');
    hold on;
    gh=plot(X, max(N(:))*exp(-(X.^2)/2), 'r', 'LineWidth', 2);
    plot(X,N); set(gca,'Ylim',rg); set(gca, 'Xlim', [-mx mx]);
    hold off;
    if (nchan < 1.5)
      title('Histogram, filtered/whitened data');
    else
      title(sprintf('Histograms, filtered/whitened data, %d channels', nchan));
    end
    legend(gh, 'univariate Gaussian');

    subplot(2,2,4); cla;
    mx = max(dataMag);
    [N,X] = hist(dataMag, 100);
    Nspikes = hist(dataMag(dataMag>thresh), X);
    chi = 2*X.*chi2pdf(X.^2, nchan);
    bar(X,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    dh= bar(X,Nspikes); set(dh, 'FaceColor', sigCol);
    ch= plot(X, (max(N)/max(chi))*chi, 'r', 'LineWidth', 2);
    hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
    title('Histogram, magnitude over filtered/whitened channel(s)');
    legend([dh, ch], 'putative spike segments', 'chi-distribution, univariate Gaussian');
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
