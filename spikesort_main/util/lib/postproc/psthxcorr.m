%%@Mike's note: could still use some cleaning up

function [dts, inds, histx, histy] = psthxcorr(spiketime1, spiketime2, t0, t1, dropzeros, calchist, show)

if nargin < 3, t0 = -0.05; t1 = 0.05; end
if nargin < 5, dropzeros = false; end
if nargin < 6, calchist = true; end
if nargin < 7, show = nargout < 1; end

[dts, inds] = trialevents(spiketime1, spiketime2, t0, t1);

if dropzeros
    nonzero = dts ~= 0;
    dts = dts(nonzero);
    inds = inds(nonzero);
end

%%@now convert to ms
dts = dts*1000;
t0 = t0*1000;
t1 = t1*1000;

if calchist
    nbin = 50;
    histx = linspace(t0, t1, nbin);
    histy = hist(dts, histx);
    histy(1,end) = 2*histy(1,end); % Account for half size bins at end
    inds = inds/max(inds)*range(histy) + min(histy); %%@ scale dots to match histogram
end

if show
    cla;
    hold all;

    plot_inds = plot(dts, inds, '.');
    xlim([t0 t1]);

    if calchist
        set(plot_inds, 'Color', 0.75 .* [1 1 1]);
        if ~isempty(histy)
            plot(histx, histy, 'k');
            axis tight;
        end
        xl = xlim;
        ticks = xl(1):range(xl)/4:xl(2);
        xticks(ticks);
    end
end


if nargout < 1, clear dts; end
