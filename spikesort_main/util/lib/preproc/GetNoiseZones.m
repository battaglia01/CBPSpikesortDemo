<<<<<<< HEAD:spikesort_main/util/lib/preproc/GetNoiseZones.m
function noise_zone_idx = GetNoiseZones(data_rms, threshold, min_len)
% Estimate noise zones from root mean square (across channels) of trace
global noise_zone_idx
% Identify noise zones
noise_comps = bwconncomp(data_rms < threshold);

% Determine zone lengths
comp_lens = cellfun(@length, noise_comps.PixelIdxList);

% Use only those which satisfy min length requirement.
=======
function noise_zone_idx = GetNoiseZones(data_rms, threshold, min_len)
% Estimate noise zones from root mean square (across channels) of trace
global noise_zone_idx
% Identify noize zones
noise_comps = bwconncomp(data_rms < threshold);

% Determine zone lengths
comp_lens = cellfun(@length, noise_comps.PixelIdxList);

% Use only those which satisfy min length requirement.
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc:spikesort_main/util/lib/preproc/GetNoiseZones.m
noise_zone_idx = noise_comps.PixelIdxList(comp_lens > min_len);