function h = PlotSnippet(snippet, snipcenter, varargin)
global dataobj;

opts = inputParser();
opts.addParamValue('dt', 1);
opts.addParamValue('startpad', 1);
opts.addParamValue('endpad', 1);
opts.addParamValue('recon', []);
opts.addParamValue('cbp',    {});
opts.addParamValue('cbpamp', {});
opts.addParamValue('cbpampthresh', []);
opts.addParamValue('clust', {});
opts.addParamValue('true',  {});
opts.addParamValue('colors', []);
opts.addParamValue('ncolors', []);
opts.addParamValue('cmf', @hsv);
opts.parse(varargin{:});
opts = opts.Results;

% Do amplitude thresholding on CBP spikes if needed
if ~isempty(opts.cbpamp) && ~isempty(opts.cbpampthresh)
    for i = 1:length(opts.cbp)
        opts.cbp{i} = opts.cbp{i}(opts.cbpamp{i} > opts.cbpampthresh(i));
    end
end


% Calculate offset
snipl = size(snippet,1);
snipmidi = (snipl-1)/2 + 1;
snipx = opts.dt*((1:snipl) - snipmidi + snipcenter);

%%@MIKE'S NOTE - ADD OFFSETS -- magical factor of 1/8 below is arbitrary
%calculate offsets
plotChannelOffset = 1/8 * (mean(snippet'.^6,1)).^(1/6) * ones(snipl,1)...
                      * ([1:dataobj.whitening.nchan]-1);
plotChannelOffset = plotChannelOffset - mean(plotChannelOffset(1,:));
%plotChannelOffset = plotChannelOffset/length(snippet)^2;
%plotChannelOffset = 0*plotChannelOffset;
%plotChannelOffset = plotChannelOffset(1:length(snippet),:);

% Plot the data snippet
if isempty(opts.recon)
    plot(snipx, snippet + plotChannelOffset);
else
    plot(snipx, snippet + plotChannelOffset, 'c');
end
hold on;
axis tight

% Show reconstruction?
if ~isempty(opts.recon)
    plot(snipx, opts.recon, 'r');
end

% Note top of axis for plotting spike markers
ylim = get(gca, 'YLim');
marky = ylim(2) - 0.02*diff(ylim);

% Find CBP spikes to plot over snippet (pad a little)
findstart = snipx(1)   - opts.startpad*opts.dt;
findend   = snipx(end) + opts.endpad*opts.dt;
cbpi   = FindSpikes(findstart/opts.dt, findend/opts.dt, opts.cbp);
clusti = FindSpikes(findstart/opts.dt, findend/opts.dt, opts.clust);
truei  = FindSpikes(findstart/opts.dt, findend/opts.dt, opts.true);

% Note matching colors
if isempty(opts.colors)
    if isempty(opts.ncolors)
        opts.ncolors = max(cellfun(@length, {cbpi; clusti; truei}));
    end
    opts.colors = opts.cmf(opts.ncolors);
end

% Plot CBP, Clusters, and (if possible) Ground Truth.
%%@ NOTE: the [10 160] at the end of the legend forces a line break
%%plus nbsp, which is necessary since the markers are so large
cbph = [];
clusth = [];
trueh = [];

for i = 1:length(cbpi)
    spikeindices = cbpi{i};
    if isempty(spikeindices), continue; end

    spiketimes = opts.dt * opts.cbp{i}(spikeindices);
    cbph(end+1) = plot(spiketimes, marky * ones(size(spiketimes)), ...
        'LineStyle', 'none', ...
        'Marker', '.', ...
        'MarkerSize', 25, ...
        'Color', opts.colors(i, :), ...
        'DisplayName', ['CBP - Spike #' num2str(i) 10 160]);
    if ~isempty(opts.cbpamp)
        spikeamps = opts.cbpamp{i}(spikeindices);
        for j = 1:length(spikeamps)
            text(spiketimes(j), ylim(2), sprintf('%0.2f', spikeamps(j)), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 25);
        end
    end
end
for i = 1:length(clusti)
    spikeindices = clusti{i};
    if isempty(spikeindices), continue; end

    spiketimes = opts.dt * opts.clust{i}(spikeindices);
    clusth(end+1) = plot(spiketimes, marky * ones(size(spiketimes)), ...
        'LineStyle', 'none', ...
        'Marker', 'x', ...
        'MarkerSize', 20, ...
        'LineWidth', 2, ...
        'Color', opts.colors(i, :), ...
        'DisplayName', ['Cluster - Spike #' num2str(i) 10 160]);
end
for i = 1:length(truei)
    spikeindices = truei{i};
    if isempty(spikeindices), continue; end

    spiketimes = opts.dt * opts.true{i}(spikeindices);
    trueh(end+1) = plot(spiketimes, marky * ones(size(spiketimes)), ...
        'LineStyle', 'none', ...
        'Marker', 'o', ...
        'MarkerSize', 15, ...
        'LineWidth', 2, ...
        'Color', opts.colors(i, :), ...
        'DisplayName', ['Truth - Spike #' num2str(i) 10 160]);
end
legend([cbph clusth trueh]);
xlabel('Time (sec)')

set(gca(), 'XLim', [findstart findend]);
hold off
if nargout > 0, h = GetCalibrationFigure(); end


function ispikes = FindSpikes(snipstart, snipend, spikes)
% FindSpikes
% usage: ispikes = FindSpikes(snipcenter, snipwidth, spikes)
%
% Get indices of spikes contained within snippet at SNIPCENTER with
% SNIPWIDTH
%
ncells = length(spikes);
ispikes = cell(ncells, 1);
for i = 1:ncells
    ispikes{i} = find(spikes{i} >= snipstart & spikes{i} <= snipend);
end
