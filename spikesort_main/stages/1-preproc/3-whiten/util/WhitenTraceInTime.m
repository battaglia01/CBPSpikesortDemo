function [ECwhitened, whitening_filter] = ...
    WhitenTraceInTime(EC, noise_acf, reg_const)

    num_acf_lags = length(noise_acf) - 1;
    % Estimate the noise autocorrelation function.
    if (mod(num_acf_lags, 2) ~= 0)
        error('num_acf_lags must be even!');
    end

    % Compute a whitening filter by inverting the autocovariance matrix
    T = toeplitz(noise_acf);

    % Make sure this is positive definite!!!
    T = sqrtm(T' * T);
    if (norm(T - toeplitz(noise_acf)) > 1e-5)
        fprintf('Warning: toeplitz(noise_acf) was not positive definite. Forcing it.\n');
    end
    NoiseCovMtx = sqrtm(inv(T + reg_const * eye(length(noise_acf))));

    whitening_filter = NoiseCovMtx(:, ceil(size(NoiseCovMtx, 2) / 2));
    % Whiten the trace
    ECwhitened = conv(EC, whitening_filter);
    ECwhitened = ECwhitened(ceil(num_acf_lags / 2) : ...
                 ceil(num_acf_lags / 2) + size(EC, 1) - 1, :);
end