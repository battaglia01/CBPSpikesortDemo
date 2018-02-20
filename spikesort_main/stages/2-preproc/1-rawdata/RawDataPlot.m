function RawDataPlot(disable)
global params dataobj;

if nargin == 1 & ~disable
    DisableCalibrationTab('Raw Data Stage');
    return;
end

rawdata = dataobj.rawdata;

% -------------------------------------------------------------------------
% Display raw data, and Fourier  amplitude
    plotDur = min(params.rawdata.min_plot_dur,rawdata.nsamples);
    plotT0 = round((rawdata.nsamples-plotDur)/2);
    inds = plotT0+[1:plotDur]; % opens a "plotDur"-width window in the middle of the sample
    params.rawdata.data_plot_inds = inds;

    plotChannelOffset = 2*std(rawdata.data(:))*ones(length(inds),1)*([1:rawdata.nchan]-1);

    %%%PLOT TIME DOMAIN
    t_rd = AddCalibrationTab('Raw Data Stage');
    
    subplot(2,1,1); cla;
    
    plot([inds(1), inds(end)]*rawdata.dt, [0 0], 'k');
    hold on;
    plot((inds-1)*rawdata.dt, rawdata.data(:,inds)'+ plotChannelOffset);
    hold off

    axis tight; xlabel('time (sec)');  ylabel('voltage');
    title(sprintf('Raw data, nChannels=%d, %.1fkHz', rawdata.nchan, 1/(1000*rawdata.dt)));

    %Plot Fourier transform
    subplot(2,1,2); cla;

    noiseCol = [1 0.3 0.3];
    dftMag = abs(fft(rawdata.data,[],2));
    if (rawdata.nchan > 1.5), dftMag = sqrt(mean(dftMag.^2)); end;
    maxDFTind = floor(rawdata.nsamples/2);
    maxDFTval = 1.2*max(dftMag(2:maxDFTind));
    hold on;
    if (~isempty(params.filtering.freq))
      yr = [min(dftMag(2:maxDFTind)), maxDFTval];
      xr = [0 params.filtering.freq(1)];
      patch([xr xr(2) xr(1)], [yr(1) yr yr(2)], noiseCol);
      if (length(params.filtering.freq) >  1)
          f2 = params.filtering.freq(2);
          if (f2 < 1/(rawdata.dt*2))
            xr = [f2 1/(rawdata.dt*2)];
            patch([xr xr(2) xr(1)], [yr(1) yr yr(2)], noiseCol);
          end
      end
      legend('Frequencies to be filtered');
    end
    plot(([1:maxDFTind]-1)/(maxDFTind*rawdata.dt*2), dftMag(1:maxDFTind));
    hold off;

    axis tight; set(gca,'Ylim', [0 maxDFTval]);  set(gca, 'Yscale', 'log');
    xlabel('frequency (Hz)'); ylabel('amplitude');
    title('Fourier amplitude, averaged over channels');
end
