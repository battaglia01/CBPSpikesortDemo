function NoiseCovMtx = EstimateNoiseCovMtx(noise_zone_idx, EC)
    noise_zones = GetSnippetsFromCellRanges(noise_zone_idx, EC);
    noise = cell2mat(noise_zones(:));
    noise = noise - repmat(mean(noise, 1), size(noise, 1), 1);
    NoiseCovMtx = noise' * noise ./ size(noise, 1);
end
