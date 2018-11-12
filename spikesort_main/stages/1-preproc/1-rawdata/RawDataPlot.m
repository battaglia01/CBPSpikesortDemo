function RawDataPlot(command)
    global params dataobj;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Raw Data');
        return;
    end

    rawdata = dataobj.rawdata;

% -------------------------------------------------------------------------
% Plot Time Domain (top subplot)
    t_rd = CreateCalibrationTab('Raw Data', 'RawData');

    subplot(2,1,1);
    cla;

    %get channel offset
    plotChannelOffset = 2*std(rawdata.data(:))*ones(rawdata.nsamples,1)*([1:rawdata.nchan]-1);

    %plot zero-crossing
    hold on;
    plot([0 (rawdata.nsamples-1)*rawdata.dt], [0 0], 'k');

    %plot channels
    plot((0:rawdata.nsamples-1)*rawdata.dt, rawdata.data' + plotChannelOffset);
    hold off

    RegisterScrollAxes(gca);
    scrollzoomplot(gca);
    xlabel('Time (sec)');
    ylabel('Voltage');
    title(sprintf('Raw data, nChannels=%d, %.1fkHz', rawdata.nchan, 1/(1000*rawdata.dt)));

% -------------------------------------------------------------------------
% Plot Frequency Domain (bottom subplot)
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
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title('Fourier amplitude, averaged over channels');
end
