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
    data = filtering.data;
    dataMag = sqrt(sum(data.^2, 1));    %%@ RMS - RSS

    nchan = size(data,1);
    thresh = params.whitening.noise_threshold;

    minZoneLen = params.whitening.min_zone_len;
    if isempty(minZoneLen)
        minZoneLen = params.general.spike_waveform_len/2;
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

    noiseCol = [1 0.4 0.4]; %red polygon color behind noise segments
    plots = {};

    % first do noise zone patches, if it isn't empty
    if ~isempty(noiseZones)
        for n=1:size(filtering.data,1)
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
    for n=1:size(filtering.data,1)
        plots{end+1} = [];
        plots{end}.dt = filtering.dt;
        plots{end}.y = filtering.data(n,:)';
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
    %%@ RMS - RSS
    dftMag = abs(fft(filtering.data,[],2));
    if (nchan > 1.5)
        dftMag = sqrt(sum(dftMag.^2));    %%@ RMS - RSS
    end
    plot(([1:maxDFTind]-1)/(maxDFTind*filtering.dt*2), dftMag(1:maxDFTind));
    set(gca,'Yscale','log'); axis tight;
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title('Fourier amplitude, filtered data');

% -------------------------------------------------------------------------
% Plot Filtered Data Histogram (top-right subplot)
    subplot(2,2,2); cla;

    %%@ RMS - RSS (would need to get rid of factor of nchan or make it sqrt(nchan))
    sd = sqrt(sum(cellfun(@(c) sum(dataMag(c).^2), noiseZones)) / ...
              (nchan*sum(cellfun(@(c) length(c), noiseZones))));
    mx = max(abs(filtering.data(:)));
    % Rice rule for histogram binsizes
    nbins = min(100, 2*size(filtering.data,2)^(1/3));
    % OLD - Freedman–Diaconis rule for histogram binsize
    % nbins = size(datain.data,2)^(1/3) / (2*iqr(datain.data(:)));
    X = linspace(-mx, mx, nbins);
    N = hist(filtering.data', X);

    plot(X, N);
    set(gca, 'Yscale', 'log');
    rg = get(gca, 'Ylim');
    rg(2) = rg(2)*10; % leave extra room for legend

    hold on;
    gh = plot(X, max(N(:))*exp(-(X.^2)/(2*sd.^2)), 'r', 'LineWidth', 2);
    set(gca, 'Ylim', rg);
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

    [N,X] = hist(dataMag, nbins);
    [Nnoise] = hist(dataMag(noiseZoneInds), X);
    chi = 2*(X/sd).*chi2pdf((X/sd).^2, nchan); %%@ RMS - RSS

    h = bar(X,N);
    set(gca,'Yscale','log');
    yrg = get(gca, 'Ylim');
    hold on;

    dh = bar(X,Nnoise);
    set(dh, 'FaceColor', noiseCol, 'BarWidth', 1);
    ch = plot(X, (max(N)/max(chi))*chi, 'k', 'LineWidth', 2);
    hold off;

    set(gca, 'Ylim', yrg);
    xlabel('RMS magnitude (over all channels)');
    legend([h, dh, ch], 'Filtered data (combined channels)', 'Noise regions', ...
           'Chi-distribution, fit to noise regions');
    title('Histogram, cross-channel magnitude of filtered data');
end
