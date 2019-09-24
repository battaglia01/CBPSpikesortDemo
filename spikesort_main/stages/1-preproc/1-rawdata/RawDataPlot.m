% Calibration for raw data loading:
%   Fig 1a shows the raw data.
%   Fig 2a plots the Fourier amplitude (averaged across channels).

function RawDataPlot(command)
    global CBPdata params CBPInternals;

    if nargin == 1 & isequal(command, 'disable')
        DeleteCalibrationTab('Raw Data');
        return;
    end

% -------------------------------------------------------------------------
% Plot Time Domain (top subplot)
    t_rd = CreateCalibrationTab('Raw Data', 'RawData');

    subplot(2,1,1);
    cla;

    %plot channels
    plots = {};
    for n=1:size(CBPdata.rawdata.data,1)
        plots{end+1} = [];
        plots{end}.dt = CBPdata.rawdata.dt;
        plots{end}.y = CBPdata.rawdata.data(n,:)';
    end

    PyramidZoomMultiPlot(plots);
    RegisterScrollAxes(gca);

    multiplotxlabel('Time (sec)');
    multiplotylabel('Voltage');
    multiplottitle(sprintf('Raw data, nChannels=%d, %.1fkHz', CBPdata.rawdata.nchan, 1/(1000*CBPdata.rawdata.dt)));

% -------------------------------------------------------------------------
% Plot Frequency Domain (bottom subplot)
    subplot(2,1,2);
    cla;

    % Get DFT Magnitude. If multiple channels, take the RMS of the magnitude
    % of each frequency
    dftMag = abs(fft(CBPdata.rawdata.data,[],2));
    if (CBPdata.rawdata.nchan > 1)
        dftMag = sqrt(sum(dftMag.^2));        %%@ RMS - RSS
    end

    % Add indicator as to which frequencies are going to be filtered, unless
    % filtering frequencies are empty
    maxDFTind = floor(CBPdata.rawdata.nsamples/2);
    minDFTval = min(dftMag(2:maxDFTind));
    maxDFTval = 1.2*max(dftMag(2:maxDFTind));
    hold on;
    if (~isempty(params.filtering.freq))
        % plot noise polygon
        noisecolor = [1 0.3 0.3];
        yr = [minDFTval, maxDFTval];
        xr = [0 params.filtering.freq(1)];
        patch([xr xr(2) xr(1)], [yr(1) yr yr(2)], noisecolor);
        if (length(params.filtering.freq) >  1)
            f2 = params.filtering.freq(2);
            if (f2 < 1/(CBPdata.rawdata.dt*2))
                xr = [f2 1/(CBPdata.rawdata.dt*2)];
                patch([xr xr(2) xr(1)], [yr(1) yr yr(2)], noisecolor);
            end
        end
        legend('Frequencies to be filtered');
    end
    plot(([1:maxDFTind]-1)/(maxDFTind*CBPdata.rawdata.dt*2), dftMag(1:maxDFTind), 'HandleVisibility', 'off');
    hold off;

    axis tight; set(gca,'Ylim', [0 maxDFTval]);  set(gca, 'Yscale', 'log');
    xlabel('Frequency (Hz)'); ylabel('Amplitude');
    title('Fourier amplitude, averaged over channels');
end
