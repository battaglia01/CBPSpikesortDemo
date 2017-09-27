<<<<<<< HEAD
function DisplaySortedSpikes(whitening, spike_times, spike_amps, init_waveforms, ...
                             snippets, recon_snippets, ...
                             params)

nchan=size(whitening.data,1);

%** Add residuals

AddCalibrationTab('CBP Results');

subplot(2,2,1);  cla;
inds = params.rawdata.data_plot_inds;
plotChannelOffset = 6*ones(length(inds),1)*([1:nchan]-1); %**magic number
plot((inds-1)*whitening.dt, whitening.data(:,inds)' + plotChannelOffset, 'k');
axis tight
yrg = get(gca,'Ylim');   xrg = get(gca,'Xlim');
title(sprintf('Data, filtered & whitened, nChannels=%d, %.1fkHz', nchan, 1/(1000*whitening.dt)));


subplot(2,2,2);  cla;
bandHt = 0.12;
yinc = bandHt*(yrg(2)-yrg(1))/length(init_waveforms);
clrs = hsv(length(init_waveforms));
patch([xrg'; xrg(2); xrg(1)], [yrg(2)*[1;1]; (yrg(1)+(1+bandHt)*(yrg(2)-yrg(1)))*[1;1]], ...
      0.9*[1 1 1], 'EdgeColor', 0.9*[1 1 1]);
set(gca,'Ylim', [yrg(1), yrg(2)+bandHt*(yrg(2)-yrg(1))]);
hold on
%** Should do proper interpolation
midChan = ceil(nchan/2);
for n=1:length(init_waveforms)
    spkInds = (spike_times{n} > inds(1)) & (spike_times{n} < inds(end));
    tInds = spike_times{n}(spkInds);
    plot((tInds-1)*whitening.dt, (yrg(2)+(n-0.5)*yinc)*ones(1,length(tInds)), '.', 'Color', clrs(n,:));
    trace = zeros(length(inds),nchan);
    trace(round(tInds)-inds(1)+1,midChan) = spike_amps{n}(spkInds)';
    trace = conv2(trace, reshape(init_waveforms{n},[],nchan), 'same');
    plot((inds-1)*whitening.dt, trace + plotChannelOffset, 'Color', clrs(n,:));
    plot((inds-1)*whitening.dt, plotChannelOffset, 'k');
end
hold off
xlabel('time (sec)');
title('Recovered spikes');

% Residual Histograms
resid = cell2mat(cellfun(@(c,cr) c-cr, snippets, recon_snippets, 'UniformOutput', false));
subplot(2,2,3); cla;
%mx = max(cellfun(@(c) max(abs(c(:))), snippets));
mx = max(abs(whitening.data(:)));
[N, Xax] = hist(resid, mx*[-50:50]/101);
plot(Xax,N); set(gca,'Yscale','log'); rg=get(gca,'Ylim');
hold on
gh=plot(Xax, max(N(:))*exp(-(Xax.^2)/2), 'r', 'LineWidth', 2);
plot(Xax,N); set(gca,'Ylim',rg); set(gca, 'Xlim', [-mx mx]);
hold off;
if (nchan < 1.5)
    title('Histogram, spikes removed');
else
    title(sprintf('Histograms, spikes removed (%d channels)', nchan));
end
legend(gh, 'univariate Gaussian');


subplot(2,2,4); cla;
mx = max(sqrt(sum(whitening.data.^2,1)));
[N,Xax] = hist(sqrt(sum(resid.^2, 2)), mx*[0:100]/100);
chi = 2*Xax.*chi2pdf(Xax.^2, nchan);
bar(Xax,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
hold on;
ch= plot(Xax, (max(N)/max(chi))*chi, 'r', 'LineWidth', 2);
hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
title('Histogram, magnitude with spikes removed');
legend(ch, 'chi-distribution, univariate Gaussian');

%   Fig6: projection into PC space of segments, with spike assignments (as in paper)
=======
function DisplaySortedSpikes(whitening, spike_times, spike_amps, init_waveforms, ...
                             snippets, recon_snippets, ...
                             params)

nchan=size(whitening.data,1);

%** Add residuals

AddCalibrationTab('CBP Results');

subplot(2,2,1);  cla;
inds = params.rawdata.data_plot_inds;
plotChannelOffset = 6*ones(length(inds),1)*([1:nchan]-1); %**magic number
plot((inds-1)*whitening.dt, whitening.data(:,inds)' + plotChannelOffset, 'k');
axis tight
yrg = get(gca,'Ylim');   xrg = get(gca,'Xlim');
title(sprintf('Data, filtered & whitened, nChannels=%d, %.1fkHz', nchan, 1/(1000*whitening.dt)));


subplot(2,2,2);  cla;
bandHt = 0.12;
yinc = bandHt*(yrg(2)-yrg(1))/length(init_waveforms);
clrs = hsv(length(init_waveforms));
patch([xrg'; xrg(2); xrg(1)], [yrg(2)*[1;1]; (yrg(1)+(1+bandHt)*(yrg(2)-yrg(1)))*[1;1]], ...
      0.9*[1 1 1], 'EdgeColor', 0.9*[1 1 1]);
set(gca,'Ylim', [yrg(1), yrg(2)+bandHt*(yrg(2)-yrg(1))]);
hold on
%** Should do proper interpolation
midChan = ceil(nchan/2);
for n=1:length(init_waveforms)
    spkInds = (spike_times{n} > inds(1)) & (spike_times{n} < inds(end));
    tInds = spike_times{n}(spkInds);
    plot((tInds-1)*whitening.dt, (yrg(2)+(n-0.5)*yinc)*ones(1,length(tInds)), '.', 'Color', clrs(n,:));
    trace = zeros(length(inds),nchan);
    trace(round(tInds)-inds(1)+1,midChan) = spike_amps{n}(spkInds)';
    trace = conv2(trace, reshape(init_waveforms{n},[],nchan), 'same');
    plot((inds-1)*whitening.dt, trace + plotChannelOffset, 'Color', clrs(n,:));
    plot((inds-1)*whitening.dt, plotChannelOffset, 'k');
end
hold off
xlabel('time (sec)');
title('Recovered spikes');

% Residual Histograms
resid = cell2mat(cellfun(@(c,cr) c-cr, snippets, recon_snippets, 'UniformOutput', false));
subplot(2,2,3); cla;
%mx = max(cellfun(@(c) max(abs(c(:))), snippets));
mx = max(abs(whitening.data(:)));
[N, Xax] = hist(resid, mx*[-50:50]/101);
plot(Xax,N); set(gca,'Yscale','log'); rg=get(gca,'Ylim');
hold on
gh=plot(Xax, max(N(:))*exp(-(Xax.^2)/2), 'r', 'LineWidth', 2);
plot(Xax,N); set(gca,'Ylim',rg); set(gca, 'Xlim', [-mx mx]);
hold off;
if (nchan < 1.5)
    title('Histogram, spikes removed');
else
    title(sprintf('Histograms, spikes removed (%d channels)', nchan));
end
legend(gh, 'univariate Gaussian');


subplot(2,2,4); cla;
mx = max(sqrt(sum(whitening.data.^2,1)));
[N,Xax] = hist(sqrt(sum(resid.^2, 2)), mx*[0:100]/100);
chi = 2*Xax.*chi2pdf(Xax.^2, nchan);
bar(Xax,N); set(gca,'Yscale','log'); yrg= get(gca, 'Ylim');
hold on;
ch= plot(Xax, (max(N)/max(chi))*chi, 'r', 'LineWidth', 2);
hold off; set(gca, 'Ylim', yrg); set(gca, 'Xlim', [0 mx]);
title('Histogram, magnitude with spikes removed');
legend(ch, 'chi-distribution, univariate Gaussian');

%   Fig6: projection into PC space of segments, with spike assignments (as in paper)
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
