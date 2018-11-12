% Default parameters, assembled into a hierarchical structure to clarify which are used where.
function FillInDefaultParameters
global params;

setparamifndef('params.general.calibration_mode', 'true');

setparamifndef('params.plotting.calibration_figure','441418467');    % magic number for calibration plotting
setparamifndef('params.plotting.params_figure','441418468');         % magic number for calibration plotting
setparamifndef('params.plotting.data_plot_times','[]');              % indices of timeseries to display in diagnostic figures.
                                                                      % ^^ [] means to use halfway point. set in plot_raw_data

setparamifndef('params.rawdata.waveform_len','81');                   % number of samples in spike waveform. MUST BE ODD.
setparamifndef('params.rawdata.min_plot_dur','3000');                 % min plot duration

setparamifndef('params.filtering.freq','[100 5000]');                 % Low/high cutoff in Hz, empty default means no filtering
setparamifndef('params.filtering.type','''fir1''');                   % "fir1", "butter"
setparamifndef('params.filtering.pad','5e3');                         % padding (in samples) to avoid border effects
setparamifndef('params.filtering.order','1000');                      % See Harris 2000

setparamifndef('params.whitening.noise_threshold','0.15');            % threshold, rel. to max amplitude of 1, used to detect and remove spikes, estimating
                                                                      % covariance of the remaining noise
setparamifndef('params.whitening.min_zone_len','[]');                 % minimum duration noise zone used for covariance estimation.
				                                                      % Empty => use rawdata.waveform_len/2
setparamifndef('params.whitening.num_acf_lags','120');                % duration over which to estimate ACF
setparamifndef('params.whitening.reg_const','0');                     % regularization const for making the ACF PSD

setparamifndef('params.clustering.num_waveforms','3');                % Number of cells
setparamifndef('params.clustering.spike_threshold','6');              % threshold for picking spike-containing intervals (in noise stdevs)
setparamifndef('params.clustering.window_len','[]');                  % empty => use rawdata.waveform_len
setparamifndef('params.clustering.peak_len','[]');                    % empty => use 0.5*window_len
setparamifndef('params.clustering.percent_variance','90');            % criteria for choosing # of PCs to retain
setparamifndef('params.clustering.upsample_fac','5');                 % upsampling factor
setparamifndef('params.clustering.smooth_len','5');                   % smoothing factor (in upsampled space)
setparamifndef('params.clustering.downsample_after_align','true');    % downsample after aligning

setparamifndef('params.partition.silence_threshold','4');             % threshold for silent 'break' regions (in stdevs of mag)
setparamifndef('params.partition.min_silence_len','floor(params.rawdata.waveform_len/2)');
setparamifndef('params.partition.min_snippet_len','params.rawdata.waveform_len');
setparamifndef('params.partition.max_snippet_len','1001');            % not enforced, only warnings
setparamifndef('params.partition.smooth_len','1');
setparamifndef('params.partition.min_pad_size','5');

setparamifndef('params.cbp.firing_rates','1e-3');                     % prior: probability of observering a spike in a time bin
setparamifndef('params.cbp.accuracy','0.1');                          % error allowed when interpolating waveforms
setparamifndef('params.cbp.lambda','1.5');                            % initial value of weighting on sparsity term (updated using reweight_fn)
setparamifndef('params.cbp.reweight_exp','1.5');                      % exponent of power-law prior on spike amplitudes
setparamifndef('params.cbp.reweight_fn','@(x) params.cbp.reweight_exp ./ (eps + abs(x))'); % Reweighting function for Iteration Reweighted L1 optimization:
							                                          % should be -d/dz(log(P(z))) where P(z)=(z+eps)^(-1.5)
setparamifndef('params.cbp.magnitude_threshold','1e-2');              % amplitude threshold for deleting spikes
setparamifndef('params.cbp.compare_greedy','true');                   % if true, check for isolated spikes before trying full CBP- for efficiency
setparamifndef('params.cbp.greedy_p_value','1 - 1e-5');               % tolerance for accepting greedy solution
setparamifndef('params.cbp.prefilter_threshold','0');                 % threshold below which atoms will not be used during CBP - for efficiency
setparamifndef('params.cbp.noise_sigma','1');                         % assume that noise has been whitened
setparamifndef('params.cbp.cbp_core_fn','@polar_1D_cbp_core');        % CBP core interpolation
setparamifndef('params.cbp.solve_fn','@cbp_ecos_2norm');              % Optimization solver function
setparamifndef('params.cbp.num_reweights','1e3');                     % MAX number of IRL1 iterations
setparamifndef('params.cbp.parfor_chunk_size','Inf');                 % parallelization chunk size
setparamifndef('params.cbp.debug_mode','false');                      % debug mode
setparamifndef('params.cbp.progress','true');                         % Display Java progress bar

% These parameters are for learning the waveforms.
setparamifndef('params.cbp_outer.num_iterations','2e2');              % number of learning iterations
setparamifndef('params.cbp_outer.batch_size','125');                  % batch size for learning
setparamifndef('params.cbp_outer.step_size','5e-2');                  % step size for updating waveform shapes
setparamifndef('params.cbp_outer.step_size_decay_factor','1');        % annealing
setparamifndef('params.cbp_outer.plotevery','1');                     % plot interval
setparamifndef('params.cbp_outer.stop_on_increase','false');          % stop when objective function increases
setparamifndef('params.cbp_outer.check_coeff_mtx','true');            % sanity check (true to be safe)
setparamifndef('params.cbp_outer.adjust_wfsize','@(w) w');            % called each iteration to adjust waveform size
setparamifndef('params.cbp_outer.rescale_flag','false');              % always FALSE
setparamifndef('params.cbp_outer.renormalize_features','false');      % always FALSE
setparamifndef('params.cbp_outer.reestimate_priors','false');         % always FALSE
setparamifndef('params.cbp_outer.CoeffMtx_fn','@polar_1D_sp_cnv_mtx');% convolves spikes w/waveforms
setparamifndef('params.cbp_outer.plot_every','1');                    % plotting frequency

% Parameters for picking amplitude thresholds.
setparamifndef('params.amplitude.kdepoints','32');
setparamifndef('params.amplitude.kderange','[0.3 1.0]');
setparamifndef('params.amplitude.kdewidth','5');
setparamifndef('params.amplitude.ampbins','60');    %moved from AmplitudeThresholdGUI.m

% Acceptable slack for considering two spikes a match.  In units of samples.
% Currently two-sided, but this should probably be changed.
setparamifndef('params.postproc.spike_location_slack','30');

end

function setparamifndef(p_name, p_value)
    global params;
    try
        eval([p_name ';']);
    catch
        eval([p_name ' = ' p_value ';']);
    end
end
