% Calibration for whitening:
% Fig 4: original vs. whitened autocorrelation(s), should be close to a delta
%   function (1 at 0, 0 elsewhere).  If not, try increasing
%   params.whitening.num_acf_lags.  If auto-correlation is noisy, there may not be
%   enough data samples for estimation.  This can be improved by a. increasing
%   params.whitening.noise_threshold (allow more samples) b. decreasing
%   params.whitening.num_acf_lags c. decreasing params.whitening.min_zone_len (allow
%   shorter noise zones).
% Fig 5 (multi-electrodes only): cross-channel correlation, should look like the
%   identity matrix. If not, a. increase params.whitening.num_acf_lags or b. increase
%   params.whitening.min_zone_len .  Note that this trades off with the quality of
%   the estimates (see prev).
% Fig 1: Highlighted segments of whitened data (green) will be used to estimate
%   waveforms in the next step.  These should contain spikes (and non-highlighted
%   regions should contain background noise).  Don't worry about getting all the
%   spikes: these are only used to initialize the waveforms!
% Fig 3, Top: Histograms of whitened channels - central portion should look
%   Gaussian. Bottom: Histogram of across-channel magnitude, with magnitudes of
%   highlighted segments in green.  If lots of spikes are in noise regions, reduce
%   params.whitening.noise_threshold

function WhitenPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Whitened Data, Auto-corr');
        DeleteCalibrationTab('Whitened Data, X-corr');
        DeleteCalibrationTab('Whitened Data, Amplitudes');
        return;
    end


% -------------------------------------------------------------------------
% Set up basics
    % local variables to reuse
    whitening = CBPdata.whitening;

    data_whitened = whitening.data;
    data_L2_across_channels = sqrt(sum(data_whitened .^ 2, 1));  %%@ RMS vs L2?

    % Threshold for considering noise
    %%@ Mike's addition - assume these thresholds are given in "Linf-equivalent"
    %%@ units. Also convert to L2
    nchan = size(data_whitened, 1);
    thresh = params.clustering.spike_threshold;
    L2_equivalent_thresh = ConvertLinfThresholdToL2(thresh, nchan);

    % autocorrelation stuff
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
    CreateCalibrationTab('Whitened Data, Auto-corr', 'Whiten');
    numrows = ceil(sqrt(nchan));
    t_ms = (0:dt:(length(old_acfs{1})-1) * dt)' .* 1000;
    for chan = 1:nchan
        subplot(numrows, numrows, chan);
        cla;
        p = plot(t_ms, [old_acfs{chan}, whitened_acfs{chan}], ...
                 '.-', 'LineWidth', 1, 'MarkerSize', 14);
        hold on;
        plot([t_ms(1), t_ms(end)], [0 0], 'k-');

        set(gca, 'FontSize', font_size);
        title(sprintf('Channel %d', chan));
        xlabel('Time lag (ms)');
        ylabel('Autocorrelation');
        legend(p, 'Original', 'Whitened');
    end

% -------------------------------------------------------------------------
% Plot Cross-correlation (Tab 2, only if multichan)
    if (nchan > 1.5)
      CreateCalibrationTab('Whitened Data, X-corr', 'Whiten');

      subplot(1,2,1);
      cla;

      old_cov_scl = old_cov./max(max(abs(old_cov)));
      imagesc(old_cov_scl);
      colormap(gca, gray);
      axis equal;
      axis tight;
      set(gca, 'FontSize', font_size);
      title('Orig. cross-channel covariance (scaled)');
      xlabel('channel');
      ylabel('channel');
      set(gca, 'XTick', 1 : nchan, 'YTick', 1 : nchan);
      [n,m]=size(old_cov_scl);
      [x,y]=meshgrid(1:n,1:m);
      text(x(:),y(:),num2str(old_cov_scl(:),'%5.3f'), ...
          'HorizontalAlignment','center', 'Color',[1.0 0.0 0.0]);

      subplot(1,2,2);
      cla;

      imagesc(whitened_cov);
      colormap(gca, gray);
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

    % get inds of spike peaks
    peakInds = data_L2_across_channels > L2_equivalent_thresh;
    peakLen = params.clustering.peak_len;
    for n=-peakLen:peakLen
        adj_inds = min(max(whitening.nsamples+n,1), length(data_L2_across_channels));
        peakInds = peakInds & data_L2_across_channels >= data_L2_across_channels(adj_inds);
    end
    peakInds = find(peakInds);

% -------------------------------------------------------------------------
% Plot Time Domain (tab 3, top-left subplot)
%
    CreateCalibrationTab('Whitened Data, Amplitudes', 'Whiten');
    subplot(2,2,1);
    cla;

    %plot polygons for putative spike segments
    sigCol = [0.4 1 0.5];
    plots = {};

    %first do patches
    for n = 1:size(data_whitened,1)
        tmppatch = {whitening.dt * [[1;1]*(peakInds-peakLen); ...
                    [1;1]*(peakInds+peakLen)], ...
                    (thresh)*[-1;1;1;-1]*ones(1,length(peakInds)), ...
                    sigCol, 'EdgeColor', sigCol};
       if n==1
           tmppatch(end+1:end+2) = {'DisplayName', 'Putative spike segments (for initial waveform estimation)'};
       else
           tmppatch(end+1:end+2) = {'HandleVisibility', 'off'};
       end
       plots{end+1} = [];
       plots{end}.args = tmppatch;
       plots{end}.type = 'patch';
       plots{end}.chan = n;
    end

    % now do plots
    for n = 1:size(data_whitened,1)
        plots{end+1} = [];
        plots{end}.dt = whitening.dt;
        plots{end}.y = data_whitened(n,:)';
        plots{end}.args = {'HandleVisibility', 'off'};
       plots{end}.chan = n;
    end
    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);

    panel = getappdata(gca, 'panel');
    multiplottitle('Filtered & noise-whitened data')
    multiplotxlabel('Time (sec)');
    multiplotylabel('Whitened signal (z-scored)');
    multiplotlegend('Location', 'NorthOutside');

% -------------------------------------------------------------------------
% Plot Frequency Domain (tab 3, bottom-left subplot)
%
    subplot(2,2,3);
    cla;

    maxDFTind = floor(whitening.nsamples/2);
    dftMag = abs(fft(data_whitened,[],2));
    if (nchan > 1.5)
        dftMag = sqrt(mean(dftMag.^2));  %%@ RMS vs L2?
    end
    plot(([1:maxDFTind]-1)/(maxDFTind*whitening.dt*2), dftMag(1:maxDFTind));
    set(gca, 'Yscale', 'log'); axis tight;
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title('Fourier amplitude, filtered & noise-whitened data');

% -------------------------------------------------------------------------
% Plot Data Histogram (tab 3, top-right plot)
%
    % Add to Histograms
    subplot(2,2,2);
    cla;

    % Get the histogram
    % Rice rule for histogram binsizes
    nbins = min(100, 2*size(data_whitened,2)^(1/3));
    % OLD - Freedman–Diaconis rule for histogram binsize
    % nbins = size(datain.data,2)^(1/3) / (2*iqr(datain.data(:)));
    mx = max(abs(data_whitened(:)));
    per_ch_bin_centers = linspace(-mx, mx, nbins);
    data_hist = hist(data_whitened', per_ch_bin_centers);

    % Plot histogram
    data_hist_plot = plot(per_ch_bin_centers, data_hist);
    set(gca,'Yscale','log');
    yrg = get(gca,'Ylim');
    yrg(2) = yrg(2)*10; % Mike's change - leaves extra room for legend

    % Plot estimated Gaussian
    hold on;
    gaussian_fit = max(data_hist(:))*exp(-(per_ch_bin_centers.^2)/2);
    gaussian_fit_plot = plot(per_ch_bin_centers, gaussian_fit, ...
                             'r', 'LineWidth', 2);
    set(gca, 'Ylim', yrg);
    set(gca, 'Xlim', [-mx mx]);
    hold off;

    if (nchan < 1.5)
      title('Histogram, filtered/whitened data');
    else
      title(sprintf('Histograms, filtered/whitened data, %d channels', nchan));
    end
    xlabel('Whitened signal (z-scored)');
    legend('Whitened data (combined channels)', ...
           'Gaussian, fit to non-spike segments');

% -------------------------------------------------------------------------
% Plot Histogram (tab 3, bottom-right plot)
%
    subplot(2,2,4);
    cla;

    % get estimated Chi-squared distribution
    [data_L2_hist, filt_bin_centers] = hist(data_L2_across_channels, nbins);
    spike_hist = hist(data_L2_across_channels(peakInds), ...
                      filt_bin_centers);
    chi_fit = 2*filt_bin_centers.*chi2pdf(filt_bin_centers.^2, nchan);    %%@ RMS vs L2?
    chi_fit = (max(data_L2_hist)/max(chi_fit))*chi_fit;

    % plot histogram of the cross-channel L2 signal histogram (spikes + noise)
    L2_hist_plot = bar(filt_bin_centers, data_L2_hist);
    set(gca,'Yscale','log');
    yrg = get(gca, 'Ylim');
    hold on;

    % plot the L2 spike histogram (spike snippets only)
    spike_hist_plot = bar(filt_bin_centers, spike_hist);
    set(spike_hist_plot, 'FaceColor', sigCol);
    chi_fit_plot = plot(filt_bin_centers, chi_fit, 'k', 'LineWidth', 2);
    hold off;

    %%@ Note - this originally said "RMS magnitude", but it's really an L2
    %%@ as it is root-sum-squared rather than root-mean-squared, so changed
    %%@ it
    set(gca, 'Ylim', yrg);
    set(gca, 'Xlim', [0 max(data_L2_across_channels)]);
    xlabel('L2 magnitude (over all channels)');
    legend([L2_hist_plot, spike_hist_plot, chi_fit_plot], ...
           'Whitened data (combined channels)', ...
           'Putative spike segments', ...
           'Chi-distribution, fit to non-spike segments');
    title('Histogram, magnitude over filtered/whitened channel(s)');
