% Most spikesorting programs use thresholds that are measured from
% the max-abs (aka Linf norm) of the signal, typically taken on
% all channels, at some point in time, and usually with a "windowing"
% effect (e.g. the threshold is open if it was exceeded at any time, on any
% of the C channels, within the last N samples).
%
% We tend to use thresholds that:
% 1. take either the RMS or the L2 norm of all C channels to get a
%    "mixdown" of all electrodes, and then
% 2. take another RMS/L2 of the last N samples of the mixdown.
%
% Assuming the noise is additive/white Gaussian with a mean of 0, then we
% are simply trying to convert an expected value of the Linf of N*C iid
% Gaussian variables to an expected value of the RMS or L2 of N*C iid
% Gaussian variables. Since the expected RMS is always just equal to the
% standard deviation, all we really need is an expression for the Linf of
% N*C iid Gaussian variables to convert from one to the other. We can
% multiply or divide by sqrt(N*C) to convert from L2 to RMS.
%
% This is a simple utility method that converts an expected RMS threshold
% to an expected Linf threshold, given a sample size.
%
%   out = ConvertRMSThresholdToLinf(thresh, numsamples);

function out = ConvertRMSThresholdToLinf(thresh, numsamples)
    global precomputedfactors

    % There are several expressions online to approximate the expected max
    % of an N-value Gaussian sample, most of which seem only accurate for
    % large N, whereas we expect N to be fairly small. Instead, we will
    % just do a Monte Carlo simulation of the conversion factor, and store
    % previously computed conversion factors to make this faster

    % if we haven't precomputed this, get it
    if ~isfield(precomputedfactors, "t_" + numsamples)
        % use the same random seed each time, just so thresholds are
        % predictable
        rng(12345);
        % Also, just do an N=5000 sample for now
        N = 5000;
        rms_est = zeros(1,N);
        inf_est = zeros(1,N);
        for n=1:N
            r = randn(1,numsamples);
            rms_est(n) = rms(r);
            inf_est(n) = norm(r,Inf);
        end
        precomputedfactors = setfield(precomputedfactors, "t_" + numsamples, ...
                             mean(inf_est)/mean(rms_est));
    end

    % now return the scaled value
    out = getfield(precomputedfactors, "t_" + numsamples) * thresh;

    % reset the random number generator
    rng("shuffle");
end
