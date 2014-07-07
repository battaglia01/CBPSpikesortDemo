function params = load_default_parameters()

% Default parameters, assembled into a hierarchical structure to clarify which are used where. 

general.waveform_len    = 81;    % number of samples in spike waveform
general.plot_diagnostics = true;

plotting.first_fig_num = 1;  % resetting this will make figure display start from a new base, allowing 
                             % comparison between different parameter conditions
plotting.font_size = 12;

filtering.freq  = [100];       % Low/high cutoff in Hz, empty default means no filtering
filtering.type  = 'fir1';      % "fir1", "butter"
filtering.pad   = 5e3;         % padding (in samples) to avoid border effects
filtering.order = 50;          % See Harris 2000

whitening.noise_threshold = 0.15;  % threshold, rel. to 1, used to detect and remove spikes, estimating
                                   % covariance of the remaining noise
whitening.p_norm          = 2;     % sliding-window Lp-norm is computed and thresholded
whitening.num_acf_lags    = 120;   % duration over which to estimate ACF
whitening.reg_const       = 0;     % regularization const for making the ACF PSD
whitening.min_zone_len    = [];    % minimum duration of a noise zone
				   % used for covariance estimation. Empty => use general.waveform_len/2

clustering.num_waveforms    = 3;    % Number of cells
clustering.threshold        = 8;    % threshold for picking spike-containing intervals (in stdevs))
clustering.window_len       = [];   % empty =>  use general.waveform_len
clustering.peak_len         = [];   % empty =>  use 0.5*window_len
clustering.percent_variance = 90;   % criteria for choosing # of PCs to retain
clustering.upsample_fac     = 5;    % upsampling factor
clustering.smooth_len       = 5;    % smoothing factor (in upsampled space)
clustering.downsample_after_align = true; % downsample after aligning

partition.threshold          = 3;  % threshold for silent 'break' regions (in stdevs)
partition.smooth_len         = 1;
partition.min_separation_len = floor(general.waveform_len/2);
partition.min_snippet_len    = general.waveform_len;
partition.max_snippet_len    = 1001;   % not enforced, only warnings
partition.min_pad_size       =  5;

% The polar_1D version seemed to be cutting things down too much, so leave alone
adjust_wfsize_fn = @(w) w; %polar_1D_adjust_wfsize(w, 0.1, 0.025, 301), ...

% cbp_outer  parameters are for learning the waveforms.
cbp_outer.num_iterations = 2e2;   % number of learning iterations
cbp_outer.batch_size = 125;       % batch size for learning
cbp_outer.step_size = 5e-2;       % step size for updating waveform shapes
cbp_outer.step_size_decay_factor =  1; % annealing
cbp_outer.plotevery = 1;    % plot interval
cbp_outer.stop_on_increase = false;  % stop when objective function increases
cbp_outer.check_coeff_mtx = true;  % sanity check (true to be safe)
cbp_outer.adjust_wfsize = adjust_wfsize_fn;  % called each iteration to adjust waveform size
cbp_outer.rescale_flag = false;  % always FALSE 
cbp_outer.renormalize_features =  false;  % always FALSE
cbp_outer.reestimate_priors = false;  % always FALSE
cbp_outer.CoeffMtx_fn =  @polar_1D_sp_cnv_mtx;  % convolves spikes w/waveforms
cbp_outer.plot_every = 1;   % plotting frequency    

cbp.noise_sigma = 1;  
cbp.firing_rates = [];  %prior
cbp.cbp_core_fn = @polar_1D_cbp_core;  % CBP core interpolation
cbp.solve_fn =  @cbp_ecos_2norm;  % Optimization solver function
cbp.debug_mode = false;  % debug mode
cbp.num_reweights = 1e3;  % MAX number of IRL1 iterations
cbp.magnitude_threshold = 1e-2; % amplitude threshold for deleting spikes
cbp.parfor_chunk_size = Inf;  % parallelization chunk size
cbp.num_features = [];  % number of "cells", empty => copy from params.clustering

params.general      = general;
params.plotting     = plotting;
params.filtering    = filtering;
params.whitening    = whitening;
params.clustering   = clustering;
params.partition    = partition;
params.cbp_outer    = cbp_outer;
params.cbp          = cbp;