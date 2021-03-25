% This is a simple utility method that converts an expected L2 threshold
% to an expected Linf threshold, given a sample size. It
% calls ConvertRMSThresholdToMax, which has more detail.
%
%   out = ConvertL2ThresholdToLinf(thresh, numsamples);

function out = ConvertL2ThresholdToLinf(thresh, N)
    out = 1/sqrt(N)*ConvertRMSThresholdToLinf(thresh,N);
end