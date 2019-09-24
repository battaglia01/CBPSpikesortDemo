% MinMaxPyramid.m - computes a min/max pyramid for an input.
%
% we want to set the first level of the tree to be the next-lowest power of
% 2 below the length of the input
%
% also, we want to skip the first 5 levels of the tree, so we only get 12.5%
% worst-case overhead

function pyr = MinMaxPyramid(in)
    % assert input is a vector
    assert(min(size(in)) == 1, 'Error: input must be a one-dimensional vector');

    % orient in as a row vector
    if size(in,1) > size(in,2)
        in = in';
    end

    % create pyramid structure and initialize
    pyr = [];
    % pyr.orig = in;    %we don't need this, assume we're keeping the original elsewhere
    pyr.maxpyr = {};
    pyr.minpyr = {};

    % create first level with size the next-lowest power of 2 below the
    % input
    newlen = 2^floor(log2(length(in)-1));               % low power of 2
    inds_frac = 1+(length(in)/newlen)*(0:newlen);       % equally spaced indices at new rate
    inds_low = ceil(inds_frac(1:end-1));                % low bound on integer indices
    inds_high = floor(inds_frac(2:end)-1/(4*newlen));   % upper bound on integer indices
    maxtmp = max(in(inds_low), in(inds_high));
    mintmp = min(in(inds_low), in(inds_high));


    % now do the tree and store the result in the pyramid
    for n=1:log2(length(mintmp))
        maxtmp = max([downsample(maxtmp,2);downsample(maxtmp,2,1)]);
        mintmp = min([downsample(mintmp,2);downsample(mintmp,2,1)]);

        % throw away the first five levels (downsample by 2 five times)
        % and store the result in the pyramid
        % note we already threw away the initial level by not storing it,
        % so four more to go
        if n > 5
            pyr.maxpyr{end+1} = maxtmp;
            pyr.minpyr{end+1} = mintmp;
        end
    end

    pyr.maxpyr = fliplr(pyr.maxpyr);
    pyr.minpyr = fliplr(pyr.minpyr);
end
