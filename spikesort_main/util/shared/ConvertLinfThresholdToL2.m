% This is a simple utility method that converts an expected Linf threshold
% to an expected L2 threshold, given a sample size. It eventually
% calls ConvertRMSThresholdToMax, which has more detail.
%
%   out = ConvertLinfThresholdToL2(thresh, numsamples);

function out = ConvertLinfThresholdToL2(thresh, N)
    out = thresh/ConvertL2ThresholdToLinf(1,N);
end