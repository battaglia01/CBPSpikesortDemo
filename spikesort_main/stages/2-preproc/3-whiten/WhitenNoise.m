function whitedatain = WhitenNoise(datain)
global params dataobj;

% Preprocess extracellularly recorded voltage trace by estimating noise
% and whitening if desired.
% FIXME: Appears to clip rawdata
% FIXME: In process cleaning up

data = datain.data;

% For output
log.operation = 'whitening';
log.params.general = params.general;
log.params.whitening = params.whitening;

min_zone_len = params.whitening.min_zone_len;
if isempty(min_zone_len)
    min_zone_len = floor(params.rawdata.waveform_len / 2);
end

% Noise zone estimation and whitening

%%@ Always uses RMS no matter what!!
% Root-mean-squared of data
% should really allow a more general p-norm...
 data_rms = sqrt(sum(data .^ 2, 1)); 
%%@Trying data_abs instead
%data_max = sum(abs(data));

% Estimate noise zones
noise_zone_idx = GetNoiseZones(data_rms, ...
                               params.whitening.noise_threshold, ...
                               min_zone_len);
                           
if(isempty(noise_zone_idx))
    error('WHITENING ERROR: No noise zones found! Threshold may be too high, or filtering may be suboptimal.');
end
                           
% Whiten trace if desired
[data_whitened, old_acfs, whitened_acfs, old_cov, whitened_cov] = ...
        WhitenTrace(data', ...
                    noise_zone_idx, ...
                    params.whitening.num_acf_lags, ...
                    params.whitening.reg_const, ...
                    params.general.calibration_mode);
noise_sigma = 1;
%fprintf('noise_sigma=%f\n', noise_sigma);

% Output
whitedatain = datain;

whitedatain.data = data_whitened;
whitedatain.noise_sigma = noise_sigma;
whitedatain.processing{end+1} = log;

whitedatain.noise_zone_idx = noise_zone_idx;

whitedatain.old_acfs = old_acfs;
whitedatain.whitened_acfs = whitened_acfs;
whitedatain.old_cov = old_cov;
whitedatain.whitened_cov = whitened_cov;