% function ECwhitened = ...
%    WhitenTrace(EC, noise_zone_idx, num_acf_lags, reg_const)
%
% Utility function for whiteining voltage traces, given estimated "noise
% regions" within the trace.
%
% EC : time x chan voltage trace matrix
%
% noise_zone_idx : cell array of time indices corresponding to "noise
%                  regions"
%
% num_acf_lags : number of lags at which to estimate temporal
%                autocorrelation
%
% reg_const : regularization constant to force ACF matrix to be PSD
%
% Returns the whitened trace (matrix same size as EC) ad well as the
% temporal and spatial covariance functions pre- and post-whitening

function [ECwhitened, old_acfs, whitened_acfs, ...
          NoiseCovMtx, WhitenedNoiseCovMtx] = ...
    WhitenTrace(filtered_data, noise_zone_idx, num_acf_lags, reg_const)

    fprintf('Whitening trace...\n');
    ECwhitened = zeros(size(filtered_data));
    num_channels = size(filtered_data, 2);

    if (~exist('reg_const', 'var'))
    	reg_const = 0;
    end
    nr = ceil(sqrt(num_channels));
    old_acfs = cell(num_channels, 1);
    whitened_acfs = cell(size(old_acfs));

    for channel_num=1:num_channels
        % Construct noise samples for this channel.
    	noise = cell(size(noise_zone_idx));
        for zone_num = 1 : length(noise)
            noise{zone_num} = filtered_data(noise_zone_idx{zone_num}, channel_num);
        end

        % Estimate the noise ACF for this channel
        noise_zones = GetSnippetsFromCellRanges(noise_zone_idx, ...
                                                filtered_data(:, channel_num));
        noise_acf = EstimateACFFromCells(noise_zones, num_acf_lags);
        old_acfs{channel_num} = noise_acf;

        % Whiten each channel temporally
    	ECwhitened(:, channel_num) = ...
            WhitenTraceInTime(filtered_data(:, channel_num), noise_acf, reg_const);

        whitened_noise_zones = ...
            GetSnippetsFromCellRanges(noise_zone_idx, ...
                                      ECwhitened(:, channel_num));
        whitened_noise_acf = ...
            EstimateACFFromCells(whitened_noise_zones, num_acf_lags);
        whitened_acfs{channel_num} = whitened_noise_acf;

    end

    % Now whiten in space
    NoiseCovMtx = EstimateNoiseCovMtx(noise_zone_idx, ECwhitened);
    
    % if covariance matrix is rank-deficient, throw error
    if rank(NoiseCovMtx) < size(ECwhitened,2)
        error(sprintf(...
             "ERROR: Noise covariance matrix is rank-deficient.\n" + ...
             "This usually happens when the noise threshold is too " + ...
             "high, and there aren't enough noise samples.\n" + ...
             "Increase params.whitening.noise_threshold and try again!"));
    end
    
    % otherwise, continue
    ECwhitened = WhitenTraceInSpace(ECwhitened, NoiseCovMtx, reg_const);
    WhitenedNoiseCovMtx = EstimateNoiseCovMtx(noise_zone_idx, ECwhitened);
    ECwhitened = ECwhitened';
end
