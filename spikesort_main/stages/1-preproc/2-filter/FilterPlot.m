%
% Calibration for filtering:
%   Fig 1b shows filtered data.  In the next step, noise covariance will be estimated
%   from below-threshold regions, which are indicated in red. There should be no spikes
%   in these regions.  Fig 2 shows Fourier amplitude (effects of filtering should be
%   visible).  Fig 3 shows histogram of the cross-channel magnitudes.  Below-threshold
%   portion is colored red, and should look like a chi distribution with fitted
%   variance (green curve).  If spikes appear to be included in the noise segments,
%   reduce params.whitening.noise_threshold before proceeding, or modify the filtering
%   parameters in params.filtering, and re-run the filtering step.

function FilterPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Filtered Data, Amplitudes');
        return;
    end

    filtering = CBPdata.filtering;

% -------------------------------------------------------------------------
% Set up basics
    % local variables to reuse
    data_filtered = filtering.data;
    data_L2_across_channels = sqrt(sum(data_filtered.^2, 1));    %%@ RMS vs L2?

    % Threshold for considering noise
    %%@ Mike's addition - assume these thresholds are given in "Linf-equivalent"
    %%@ units. Also convert to L2
    nchan = size(data_filtered, 1);
    thresh = params.whitening.noise_threshold;
    L2_equivalent_thresh = ConvertLinfThresholdToL2(thresh, nchan);
    
    % Noise zones
    minZoneLen = params.whitening.min_zone_len;
    noiseZones = GetNoiseZones(data_L2_across_channels, ...
                               L2_equivalent_thresh, minZoneLen);
    noiseZoneInds = cell2mat(cellfun(@(c) c', noiseZones, ...
                                     'UniformOutput', false));
    zonesL = cellfun(@(c) c(1), noiseZones);
    zonesR = cellfun(@(c) c(end), noiseZones);

% -------------------------------------------------------------------------
% Plot Time Domain (top-left subplot)
    t_filt = CreateCalibrationTab('Filtered Data, Amplitudes', 'Filter');

    subplot(2,2,1);
    cla;

    noiseCol = [1 0.4 0.4]; %red polygon color behind noise segments
    plots = {};

    % first do noise zone patches, if it isn't empty
    if ~isempty(noiseZones)
        for n=1:size(data_filtered,1)
            % do patch
            tmppatch = {filtering.dt*[[1;1]*zonesL; [1;1]*zonesR], ...
                        (thresh)*[-1;1;1;-1]*ones(1,length(zonesL)), ...
                        noiseCol, 'EdgeColor', noiseCol};
            if n==1
                tmppatch(end+1:end+2) = {'DisplayName', ...
                                         'Noise regions (to be whitened)'};
            else
                tmppatch(end+1:end+2) = {'HandleVisibility', 'off'};
            end
            plots{end+1}.args = tmppatch;
            plots{end}.type = 'patch';
            plots{end}.chan = n;
        end
    end

    % now do plots
    for n=1:size(data_filtered,1)
        plots{end+1} = [];
        plots{end}.dt = filtering.dt;
        plots{end}.y = data_filtered(n,:)';
        plots{end}.args = {'HandleVisibility', 'off'};
        plots{end}.chan = n;
    end

    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);
    hold off;

    if ~isempty(noiseZones)
        multiplotlegend('Location', 'NorthOutside');
    end
    multiplotxlabel('Time (sec)');
    multiplotylabel('Filtered signal');
    multiplottitle('Filtered data');

% -------------------------------------------------------------------------
% Plot Frequency Domain (bottom-left subplot)
    subplot(2,2,3);
    cla;
    maxDFTind = floor(filtering.nsamples/2);
    %%@ RMS vs L2?
    dftMag = abs(fft(data_filtered,[],2));
    if (nchan > 1.5)
        dftMag = sqrt(sum(dftMag.^2));    %%@ RMS vs L2?
    end
    plot(([1:maxDFTind]-1)/(maxDFTind*filtering.dt*2), dftMag(1:maxDFTind));
    set(gca,'Yscale','log'); axis tight;
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title('Fourier amplitude, filtered data');

% -------------------------------------------------------------------------
% Plot Filtered Data Histogram (top-right subplot)
    subplot(2,2,2); cla;

    % this estimates the standard deviation
    est_noise_std = sqrt(sum(cellfun(@(c) sum(data_L2_across_channels(c).^2), noiseZones)) / ...
              (nchan*sum(cellfun(@(c) length(c), noiseZones))));
    %%@ ^^ RMS vs L2? (would need to get rid of factor of nchan or make it sqrt(nchan))
    
    
    % Get the histogram
    % Rice rule for histogram binsizes
    nbins = min(100, 2*size(data_filtered,2)^(1/3));
    % OLD - Freedman–Diaconis rule for histogram binsize
    % nbins = size(datain.data,2)^(1/3) / (2*iqr(datain.data(:)));
    mx = max(abs(data_filtered(:)));
    per_ch_bin_centers = linspace(-mx, mx, nbins);
    data_hist = hist(data_filtered', per_ch_bin_centers);

    % Plot histogram
    data_hist_plot = plot(per_ch_bin_centers, data_hist);
    set(gca, 'Yscale', 'log');
    yrg = get(gca, 'Ylim');
    yrg(2) = yrg(2)*10; % Mike's change - leaves extra room for legend

    % Plot estimated Gaussian
    hold on;
    gaussian_fit = max(data_hist(:))*exp(-(per_ch_bin_centers.^2)/(2*est_noise_std.^2));
    gaussian_fit_plot = plot(per_ch_bin_centers, gaussian_fit, ...
                             'r', 'LineWidth', 2);
    set(gca, 'Ylim', yrg);
    set(gca, 'Xlim', [-mx mx]);
    hold off;

    if (nchan < 1.5)
      title('Histogram, filtered data');
    else
      title(sprintf('Histograms, filtered data (%d channels)', nchan));
    end
    xlabel('Filtered signal')
    legend('Filtered data (combined channels)', ...
           'Gaussian, fit to noise regions');

% -------------------------------------------------------------------------
% Plot Cross-Channel Histogram (bottom-right subplot)

    subplot(2,2,4);
    cla;

    % get estimated Chi-squared distribution
    [data_L2_hist, filt_bin_centers] = hist(data_L2_across_channels, nbins);
    noise_hist = hist(data_L2_across_channels(noiseZoneInds), filt_bin_centers);
    chi_fit = 2*(filt_bin_centers/est_noise_std).*chi2pdf((filt_bin_centers/est_noise_std).^2, nchan);
    chi_fit = (max(data_L2_hist)/max(chi_fit))*chi_fit;

    % plot histogram of the cross-channel L2 signal histogram (spikes + noise)
    L2_hist_plot = bar(filt_bin_centers, data_L2_hist);
    set(gca,'Yscale','log');
    yrg = get(gca, 'Ylim');
    hold on;

    % plot the L2 noise histogram (noise zones only)
    noise_hist_plot = bar(filt_bin_centers, noise_hist);
    set(noise_hist_plot, 'FaceColor', noiseCol, 'BarWidth', 1);
    chi_fit_plot = plot(filt_bin_centers, chi_fit, 'k', 'LineWidth', 2);
    hold off;

    %%@ Note - this originally said "RMS magnitude", but it's really an L2
    %%@ as it is root-sum-squared rather than root-mean-squared, so changed
    %%@ it
    set(gca, 'Ylim', yrg);
    xlabel('L2 magnitude (over all channels)');
    legend([L2_hist_plot, noise_hist_plot, chi_fit_plot], ...
           'Filtered data (combined channels)', ...
           'Noise regions', ...
           'Chi-distribution, fit to noise regions');
    title('Histogram, cross-channel magnitude of filtered data');
end
