<<<<<<< HEAD:spikesort_main/util/lib/misc/getWhiteningMtxFn.m
function WhiteningMtxFn = getWhiteningMtxFn(pars)
    if (~isfield(pars, 'whitening_mtx_fn'))
        WhiteningMtxFn = @(len) eye(len);
    else
        WhiteningMtxFn = pars.whitening_mtx_fn;
    end
end
=======
function WhiteningMtxFn = getWhiteningMtxFn(pars)
    if (~isfield(pars, 'whitening_mtx_fn'))
        WhiteningMtxFn = @(len) eye(len);
    else
        WhiteningMtxFn = pars.whitening_mtx_fn;
    end
end
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/misc/getWhiteningMtxFn.m
