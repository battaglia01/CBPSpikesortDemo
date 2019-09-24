function [acf acfs] = EstimateACFFromCells(noise_zones, num_acf_lags)
    fprintf('Averaging ACF over %d noise regions.\n', length(noise_zones));
    acfs = zeros(num_acf_lags + 1, length(noise_zones));
    for zone_num = 1 : length(noise_zones)
        acfs(:, zone_num) = ...
            EstimateACFFromSamples(noise_zones{zone_num}, num_acf_lags);
    end
    acf = sum(acfs, 2);
    acf = acf - acf(end);
    acf = acf ./ max(abs(acf));
end
