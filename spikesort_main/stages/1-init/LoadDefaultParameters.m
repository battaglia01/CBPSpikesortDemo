function FillInDefaultParameters

% Default parameters, assembled into a hierarchical structure to clarify which are used where.

general.calibration_mode    = true;

plotting.calibration_figure = 2147483646;                   % magic number for calibration plotting
plotting.verify_figure      = 2147483645;                   % magic number for calibration plotting

rawdata.waveform_len        = 81;                           % number of samples in spike waveform.  MUST BE ODD.
rawdata.min_plot_dur        = 3000;                         % min plot duration
rawdata.data_plot_inds      = [];                           % indices of timeseries to display in diagnostic figures: set in plot_raw_data

filtering.freq              = [100 5000];                   % Low/high cutoff in Hz, empty default means no filtering
filtering.type              = 'fir1';                       % "fir1", "butter"
filtering.pad               = 5e3;                          % padding (in samples) to avoid border effects
filtering.order             = 100;                           % See Harris 2000

whitening.noise_threshold   = 0.15;                         % threshold, rel. to max amplitude of 1, used to detect and remove spikes, estimating
                                                            % covariance of the remaining noise
whitening.min_zone_len      = [];                           % minimum duration noise zone used for covariance estimation.
				                                                    % Empty => use rawdata.waveform_len/2
whitening.num_acf_lags      = 120;                          % duration over which to estimate ACF
whitening.reg_const         = 0;                            % regularization const for making the ACF PSD

clustering.num_waveforms    = 3;                            % Number of cells
clustering.spike_threshold  = 6;                            % threshold for picking spike-containing intervals (in noise stdevs)
clustering.window_len       = [];                           % empty => use rawdata.waveform_len
clustering.peak_len         = [];                           % empty => use 0.5*window_len
clustering.percent_variance = 90;                           % criteria for choosing # of PCs to retain
clustering.upsample_fac     = 5;                            % upsampling factor
clustering.smooth_len       = 5;                            % smoothing factor (in upsampled space)
clustering.downsample_after_align = true;                   % downsample after aligning

partition.silence_threshold  = 4;                           % threshold for silent 'break' regions (in stdevs of mag)
partition.min_silence_len    = floor(rawdata.waveform_len/2);
partition.min_snippet_len    = rawdata.waveform_len;
partition.max_snippet_len    = 1001;                        % not enforced, only warnings
partition.smooth_len         = 1;
partition.min_pad_size       = 5;

cbp.firing_rates = 1e-3;                                    % prior: probability of observering a spike in a time bin
cbp.accuracy     = 0.1;                                     % error allowed when interpolating waveforms
cbp.lambda       = 1.5;                                     % initial value of weighting on sparsity term (updated using reweight_fn)
cbp.reweight_exp = 1.5;                                     % exponent of power-law prior on spike amplitudes
cbp.reweight_fn  = @(x) cbp.reweight_exp ./ (eps + abs(x)); % Reweighting function for Iteration Reweighted L1 optimization:
							                                % should be -d/dz(log(P(z))) where P(z)=(z+eps)^(-1.5)
cbp.magnitude_threshold = 1e-2;                             % amplitude threshold for deleting spikes
cbp.compare_greedy      = true;                             % if true, check for isolated spikes before trying full CBP- for efficiency
cbp.greedy_p_value      = 1 - 1e-5;                         % tolerance for accepting greedy solution
cbp.prefilter_threshold = 0;                                % threshold below which atoms will not be used during CBP - for efficiency
cbp.noise_sigma         = 1;                                % assume that noise has been whitened
cbp.cbp_core_fn         = @polar_1D_cbp_core;               % CBP core interpolation
cbp.solve_fn            = @cbp_ecos_2norm;                  % Optimization solver function
cbp.num_reweights       = 1e3;                              % MAX number of IRL1 iterations
cbp.parfor_chunk_size   = Inf;                              % parallelization chunk size
cbp.debug_mode          = false;                            % debug mode
cbp.progress            = true;                             % Display Java progress bar

% The polar_1D version seemed to be cutting things down too much, so leave alone
adjust_wfsize_fn  = @(w) w;                                 % polar_1D_adjust_wfsize(w, 0.1, 0.025, 301), ...

% These parameters are for learning the waveforms.
cbp_outer.num_iterations         = 2e2;                     % number of learning iterations
cbp_outer.batch_size             = 125;                     % batch size for learning
cbp_outer.step_size              = 5e-2;                    % step size for updating waveform shapes
cbp_outer.step_size_decay_factor = 1;                       % annealing
cbp_outer.plotevery              = 1;                       % plot interval
cbp_outer.stop_on_increase       = false;                   % stop when objective function increases
cbp_outer.check_coeff_mtx        = true;                    % sanity check (true to be safe)
cbp_outer.adjust_wfsize          = adjust_wfsize_fn;        % called each iteration to adjust waveform size
cbp_outer.rescale_flag           = false;                   % always FALSE
cbp_outer.renormalize_features   = false;                   % always FALSE
cbp_outer.reestimate_priors      = false;                   % always FALSE
cbp_outer.CoeffMtx_fn            = @polar_1D_sp_cnv_mtx;    % convolves spikes w/waveforms
cbp_outer.plot_every             = 1;                       % plotting frequency

% Parameters for picking amplitude thresholds.
amplitude.kdepoints = 32;
amplitude.kderange  = [0.3 1.0];
amplitude.kdewidth  = 5;

% Acceptable slack for considering two spikes a match.  In units of samples.
% Currently two-sided, but this should probably be changed.
postproc.spike_location_slack = 30;

% Parameters for sonification
sonify.base_freq = 261.6;
sonify.ratios = [4 5 6 7 9 11 13 15 11 19 21 23];
sonify.note_duration = 0.1;
sonify.time_stretch = 2;
sonify.sound_duration = 10;

params.general      = general;
params.plotting     = plotting;
params.rawdata      = rawdata;
params.filtering    = filtering;
params.whitening    = whitening;
params.clustering   = clustering;
params.partition    = partition;
params.cbp          = cbp;
params.cbp_outer    = cbp_outer;
params.amplitude    = amplitude;
params.postproc     = postproc;
params.sonify       = sonify;

end