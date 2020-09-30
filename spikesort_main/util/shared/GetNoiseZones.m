% Estimate noise zones from root mean square (across channels) of trace
function noise_zone_idx = GetNoiseZones(data_L2_across_channels, threshold, min_len)
   
    % Identify noise zones
    noise_zones = bwconncomp(data_L2_across_channels < threshold);

    % Determine zone lengths
    comp_lens = cellfun(@length, noise_zones.PixelIdxList);

    % Use only those which satisfy min length requirement.
    noise_zone_idx = noise_zones.PixelIdxList(comp_lens > min_len);
end