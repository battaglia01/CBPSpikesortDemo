<<<<<<< HEAD:spikesort_main/util/lib/postproc/psthxcorr.m
%%@Mike's note: this function is the absolute devil. The linkaxpos thing
%%glitches out in the tabbed window for some reason. plotyy exists but is
%%awful to work with and will be deprecated soon. yyaxis is 2016a only.
%%Argh.

function [dts inds, histx, histy] = psthxcorr(spiketime1, spiketime2, t0, t1, dropzeros, calchist, show)

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

if calchist
    nbin = 50;
    histx = linspace(t0, t1, nbin);
    histy = hist(dts, histx);
    histy(1,end) = 2*histy(1,end); % Account for half size bins at end
end


if show
    rax = gca();
    rh = plot(dts, inds, '.');
    set(rax, 'XLim', [t0 t1]);
    set(rax, 'YLim', [0 length(spiketime2)+1])
    
    if calchist
        set(rh, 'Color', 0.75 .* [1 1 1]);
        hold on;
        hax = axes('Position', get(rax, 'Position'));
        if ~isempty(histy), plot(hax, histx, histy, 'k'); end
        set(hax, 'YAxisLocation', 'right', 'XLim', get(rax, 'XLim'), 'Color', 'none');
        set(hax, 'XTick', []);

        linkaxpos(rax, hax);
%        linkaxes([rax, hax], 'x'); % This is slow...
    end
end


=======
%%@Mike's note: this function is the absolute devil. The linkaxpos thing
%%glitches out in the tabbed window for some reason. plotyy exists but is
%%awful to work with and will be deprecated soon. yyaxis is 2016a only.
%%Argh.

function [dts inds, histx, histy] = psthxcorr(spiketime1, spiketime2, t0, t1, dropzeros, calchist, show)

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

if calchist
    nbin = 50;
    histx = linspace(t0, t1, nbin);
    histy = hist(dts, histx);
    histy(1,end) = 2*histy(1,end); % Account for half size bins at end
end


if show
    rax = gca();
    rh = plot(dts, inds, '.');
    set(rax, 'XLim', [t0 t1]);
    set(rax, 'YLim', [0 length(spiketime2)+1])
    
    if calchist
        set(rh, 'Color', 0.75 .* [1 1 1]);
        hold on;
        hax = axes('Position', get(rax, 'Position'));
        if ~isempty(histy), plot(hax, histx, histy, 'k'); end
        set(hax, 'YAxisLocation', 'right', 'XLim', get(rax, 'XLim'), 'Color', 'none');
        set(hax, 'XTick', []);

        linkaxpos(rax, hax);
%        linkaxes([rax, hax], 'x'); % This is slow...
    end
end


>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/postproc/psthxcorr.m
if nargout < 1, clear dts; end