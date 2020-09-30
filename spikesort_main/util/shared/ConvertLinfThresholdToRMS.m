% This is a simple utility method that converts an expected Linf threshold
% to an expected RMS threshold, given a sample size. It eventually
% calls ConvertRMSThresholdToMax, which has more detail.
%
%   out = ConvertLinfThresholdToRMS(thresh, numsamples);

function out = ConvertLinfThresholdToRMS(thresh, N)
    out = thresh/ConvertRMSThresholdToLinf(1,N);
end