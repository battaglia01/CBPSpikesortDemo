function WhitenPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DisableCalibrationTab('Whitened Data, auto-corr');
        DisableCalibrationTab('Whitened Data, x-corr');
        DisableCalibrationTab('Whitened Data, roundup');
        return;
    end
    
    whitening = dataobj.whitening;

% -------------------------------------------------------------------------
% Set up basics
    % local variables to reuse
    data_whitened = whitening.data;
    
    %autocorrelation stuff
    old_acfs = whitening.old_acfs;
    whitened_acfs = whitening.whitened_acfs;
    old_cov = whitening.old_cov;
    whitened_cov = whitening.whitened_cov;

    % Visualization of noise zone estimation
    dt = whitening.dt;
    font_size = 12;
    nchan = size(data_whitened, 1);

% -------------------------------------------------------------------------
% Plot Autocorrelation (Tab 1)
    AddCalibrationTab('Whitened Data, auto-corr');
    numrows = ceil(sqrt(nchan));
    t_ms = (0:dt:(length(old_acfs{1})-1) * dt)' .* 1000;
    for chan = 1:nchan
        subplot(numrows, numrows, chan);
        cla;
        plot(t_ms, [old_acfs{chan}, whitened_acfs{chan}], ...
              '.-', 'LineWidth', 1, 'MarkerSize', 14);
        set(gca, 'FontSize', font_size);
        xlabel('time lag (ms)');
        ylabel('autocorrelation');
        legend('original', 'whitened');
        hold on; plot([t_ms(1), t_ms(end)], [0 0], 'k-');
        title(sprintf('Channel %d', chan));
    end
    
% -------------------------------------------------------------------------
% Plot Cross-correlation (Tab 2, only if multichan)
    if (nchan > 1.5)
      AddCalibrationTab('Whitened Data, x-corr');
      
      subplot(1,2,1);
      cla;
      
      old_cov_scl = old_cov./max(max(abs(old_cov)));
      imagesc(old_cov_scl);
      colormap(gray);
      axis equal; axis tight;
      set(gca, 'FontSize', font_size);
      title('Orig. cross-channel covariance (scaled)');
      xlabel('channel');    ylabel('channel');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
      [n,m]=size(old_cov_scl);
      [x,y]=meshgrid(1:n,1:m);
      text(x(:),y(:),num2str(old_cov_scl(:),'%5.3f'), ...
          'HorizontalAlignment','center', 'Color',[1.0 0.0 0.0]);
      
      subplot(1,2,2);
      cla;
      imagesc(whitened_cov);
      colormap(gray);
      axis equal; axis tight;
      set(gca, 'FontSize', font_size);
      xlabel('channel');
      title('Whitened cross-channel covariance (unscaled)');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
      [n,m]=size(whitened_cov);
      [x,y]=meshgrid(1:n,1:m);
      text(x(:),y(:),num2str(whitened_cov(:),'%5.3f'), ...
          'HorizontalAlignment','center', 'Color',[1.0 0.0 0.0]);
    end

% -------------------------------------------------------------------------
% Plot Roundup (tab 3)
%
% Set up basics for this tab
    %%@ copied from preproc/EstimateInitialWaveforms.m:
    
    %get magnitude
    dataMag = sqrt(sum(data_whitened .^ 2, 1));     %%@Hard-coded RMS again
    
    %threshold for considering a spike
    thresh = params.clustering.spike_threshold;
    
    %get inds of spike peaks
    peakInds = dataMag > thresh;
    peakLen = params.clustering.peak_len;
    if (isempty(peakLen))
        peakLen=floor(params.rawdata.waveform_len/2);
    end
    for i = -peakLen : peakLen
        adj_inds = min(max(whitening.nsamples+i,1),length(dataMag));
        peakInds = peakInds & dataMag >= dataMag(adj_inds);
    end
    peakInds = find(peakInds);
    
% -------------------------------------------------------------------------
% Plot Time Domain (tab 3, top-left subplot)
%
    AddCalibrationTab('Whitened Data, roundup');
    subplot(2,2,1);
    cla;
    sigCol = [0.4 1 0.5];

    %calculate offsets
    plotChannelOffset = 2*(mean(data_whitened(:).^6)).^(1/6)*ones(whitening.nsamples,1)*([1:nchan]-1);
    plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));
    mxOffset = plotChannelOffset(1,end);
    
    %plot polygons for putative spike segments
    hold on;
    sh = patch(whitening.dt*[[1;1]*(peakInds-peakLen); [1;1]*(peakInds+peakLen)], ...
          (mxOffset+thresh)*[-1;1;1;-1]*ones(1,length(peakInds)), sigCol,'EdgeColor',sigCol);
    
    %plot channels
    plot((0:whitening.nsamples-1)*whitening.dt, data_whitened' + plotChannelOffset);
    hold off;
    
    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    title('Filtered & noise-whitened data')
    xlabel('time (sec)');
    ylabel('amplitude (in standard deviations)');
    legend('putative spike segments (for initial waveform estimation)');

% -------------------------------------------------------------------------
% Plot Frequency Domain (tab 3, bottom-left subplot)
%
    %%@GetCalibrationTab('Frequency Domain');
    subplot(2,2,3); cla;
    maxDFTind = floor(whitening.nsamples/2);
    dftMag = abs(fft(data_whitened,[],2));
    if (nchan > 1.5), dftMag = sqrt(mean(dftMag.^2)); end;
    plot(([1:maxDFTind]-1)/(maxDFTind*whitening.dt*2), dftMag(1:maxDFTind));
    set(gca, 'Yscale', 'log'); axis tight;
    xlabel('frequency (Hz)'); ylabel('amplitude');
    title('Fourier amplitude, filtered & noise-whitened data');

% -------------------------------------------------------------------------
% Plot Data Histogram (tab 3, top-right plot)
%
    %Add to Histograms
    %%@GetCalibrationTab('Data Histograms');
    subplot(2,2,2); cla;
    mx = max(abs(data_whitened(:)));
    [N, X] = hist(data_whitened',100);
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

% -------------------------------------------------------------------------
% Plot Histogram (tab 3, bottom-right plot)
%
    subplot(2,2,4); cla;
    mx = max(dataMag);
    [N,X] = hist(dataMag, 100);
    Nspikes = hist(dataMag(dataMag>thresh), X);
    chi = 2*X.*chi2pdf(X.^2, nchan);
    bar(X,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
    hold on;
    dh= bar(X,Nspikes); set(dh, 'FaceColor', sigCol);
    ch= plot(X, (max(N)/max(chi))*chi, 'k', 'LineWidth', 2);
    hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
    title('Histogram, magnitude over filtered/whitened channel(s)');
    legend([dh, ch], 'putative spike segments', 'chi-distribution, univariate Gaussian');
