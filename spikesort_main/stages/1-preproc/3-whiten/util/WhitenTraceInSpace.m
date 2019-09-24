function ECwhitened = WhitenTraceInSpace(EC, NoiseCovMtx, reg_const)
    % Estimate noise covariance matrix from noise samples.
    WhiteningMtx = sqrtm(inv(NoiseCovMtx + ...
                             reg_const * eye(size(NoiseCovMtx, 1))));

    ECwhitened = EC * WhiteningMtx';
end