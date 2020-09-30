% Default parameters, assembled into a hierarchical structure to clarify
% which are used where.

function FillInDefaultParameters
global params;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calibration mode on or off?
setparamifndef('params.plotting.calibration_mode', 'true');
% magic number for calibration plotting
setparamifndef('params.plotting.calibration_figure','441418467');
% magic number for params window
setparamifndef('params.plotting.params_figure','441418468');
% magic number for cell info window
setparamifndef('params.plotting.cell_info_figure','441418469');
% initial zoom level for scroll
setparamifndef('params.plotting.zoomlevel','1');
% initial xpos for scroll
setparamifndef('params.plotting.xpos','0');
% Raw list of cell colors to use. You can change this as need be.
% Call params.plotting.cell_color to get the colors and have it auto-cycle beyond
% the end of the list
setparamifndef('params.plotting.cell_color_rawlist','hsv(10) * 0.9');
% Function that gets a color from the raw list, and cycles if the cell index is
% beyond the end of the list
setparamifndef('params.plotting.cell_color', ...
    '@(x) params.plotting.cell_color_rawlist(1+mod(x-1,length(params.plotting.cell_color_rawlist)),:)');
% If this is set, don't display user-friendly error dialog, but rather just
% throw the error naturally - good when catching organically and doing
% stack trace stuff
setparamifndef('params.general.raw_errors', 'false');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% number of samples in spike waveform. MUST BE ODD.
setparamifndef('params.general.spike_waveform_len','81');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FILTERING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Low/high cutoff in Hz, empty default means no filtering
setparamifndef('params.filtering.freq','[100 5000]');
% Filtering type: "fir1", "butter"
setparamifndef('params.filtering.type','''fir1''');
% padding (in samples) to avoid border effects
setparamifndef('params.filtering.pad','5e3');
% Filtering order. See Harris 2000
setparamifndef('params.filtering.order','1000');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WHITENING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% threshold, rel. to estimated std of the noise, used to detect and remove
% spikes, estimating covariance of the remaining noise. For example, if you
% think "most" spikes are at least 3 times the amplitude of the noise std,
% this can be set to a value of 3.
setparamifndef('params.whitening.noise_threshold','3');
% minimum duration noise zone used for covariance estimation.
setparamifndef('params.whitening.min_zone_len',...
               'floor(params.general.spike_waveform_len/2)');
% duration over which to estimate ACF
setparamifndef('params.whitening.num_acf_lags','120');
% regularization const for making the ACF PSD
setparamifndef('params.whitening.reg_const','0');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLUSTERING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Number of spike cells to use for clustering (and CBP)
setparamifndef('params.clustering.num_waveforms','3');
%
% threshold for picking spike-containing intervals (in noise stdevs)
setparamifndef('params.clustering.spike_threshold','5');
%
% Window length - default is general.spike_waveform_len, rounded to the nearest odd value
setparamifndef('params.clustering.window_len', ...
               '2*floor(params.general.spike_waveform_len/2)+1');
%
% Peak length - default is floor(window_len/2)
setparamifndef('params.clustering.peak_len','floor(params.clustering.window_len / 2)');
%
% criteria for choosing # of PCs to retain
setparamifndef('params.clustering.percent_variance','90');
%
% upsampling factor
setparamifndef('params.clustering.upsample_fac','5');
%
% smoothing factor (in upsampled space)
setparamifndef('params.clustering.smooth_len','5');
%
% downsample after aligning
setparamifndef('params.clustering.downsample_after_align','true');
%
% Mode for aligning the peaks of "snippets" before clustering.
% When we cluster the snippets, we need to make sure they are properly
% aligned, or else we get multiple clusters that are time-shifted
% versions of one another. How do we do this alignment?
%            peak : center the peak of the waveform
%            centroid : center the sample corresponding to the first moment
%            median : center the sample in which the sum of all samples
%                     left and right of it are equal
setparamifndef('params.clustering.alignment_mode','''peak''');
%
% averaging mode for multichannel data in the clustering stage:
% if we have multiple channels, we need to mix them to a single channel to
% determine what the general peak is. how do we perform this mix?
%            L1 : sum the absolute value (L1 norm) of each sample
%                     across electrodes
%            L2 : take an RMS (L2 norm) of each sample across
%                     electrodes
%            Linf : get the max absolute value of each sample across
%                     electrodes
%            max : max signed sum across electrodes
%            min : min signed sum across electrodes
setparamifndef('params.clustering.averaging_mode','''L1''');
%
% the `similarity_method` parameter determines how we compare the
% similarity oftwo cluster centroids. Possible choices are:
%            shiftcorr: gets the minimum reflective correlation/cosine
%                       similarity between all possible time-shifts of the
%                       waveforms, which is a shift-invariant metric that
%                       is normalized between -1 and 1. (**default**)
%            shiftdist: gets the minimum distance between all possible
%                       time-shifts of the waveforms, giving a shift-invariant
%                       metric.
%            magspectrum: gets the distance of the magnitude spectra, to
%                         give a different shift-invariant metric. experimental
%            simple: gets the naive distance between two waveforms with no
%                    time-shifting compensation. May not rank two
%                    time-shifted versions of the same waveform as being
%                    close to one another
setparamifndef('params.clustering.similarity_method', '''shiftcorr''');
%
% the `kmean_mode` parameter  REdetermines what, exactly, we are taking the kmeans
% of. The settings are as follows:
%           temporal: assign snippets to clusters based on taking k-means of
%                     the raw waveform snippets, - the standard in clustering
%                     approaches. **default**
%           spectral: assign snippets to clusters based on taking k-means of
%                     the *magnitude spectrum* of each waveform snippets.
%                     This is *extremely* experimental, but *can* be useful
%                     when the usual clustering leads to multiple clusters
%                     which are close to being time-shifted versions of one
%                     another, which happens if noise should happen to shift
%                     the peak left or right, leading to wrongly aligned
%                     snippets. This tends to only work well for a small number
%                     of clusters, as there are simply too many false positives
%                     as the number increases, even with artificially
%                     orthogonalized clusters.
setparamifndef('params.clustering.kmean_mode', '''temporal''')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARTITION (sub-selection of CBP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% threshold for silent 'break' regions (in stdevs of mag)
setparamifndef('params.partition.silence_threshold','4');
setparamifndef('params.partition.min_silence_len', ...
               'floor(params.general.spike_waveform_len/2)');
setparamifndef('params.partition.min_snippet_len', ...
               'params.general.spike_waveform_len');
% not enforced, only warnings
setparamifndef('params.partition.max_snippet_len','1001');
setparamifndef('params.partition.smooth_len','1');
setparamifndef('params.partition.min_pad_size','5');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prior: probability of observering a spike in a time bin
setparamifndef('params.cbp.firing_rates','1e-3');
% error allowed when interpolating waveforms
setparamifndef('params.cbp.accuracy','0.1');
% initial value of weighting on sparsity term (updated using reweight_fn)
setparamifndef('params.cbp.lambda','1.5');
% exponent of power-law prior on spike amplitudes
setparamifndef('params.cbp.reweight_exp','1.5');
% Reweighting function for Iteration Reweighted L1 optimization:
% should be -d/dz(log(P(z))) where P(z)=(z+eps)^(-1.5)
setparamifndef('params.cbp.reweight_fn', ...
               '@(x) params.cbp.reweight_exp ./ (eps + abs(x))');
% amplitude threshold for deleting spikes
setparamifndef('params.cbp.min_valid_magnitude_threshold','1e-2');
% if true, check for isolated spikes before trying full CBP- for efficiency
setparamifndef('params.cbp.compare_greedy','true');
% tolerance for accepting greedy solution
setparamifndef('params.cbp.greedy_p_value','1 - 1e-5');
% threshold below which atoms will not be used during CBP - for efficiency
setparamifndef('params.cbp.prefilter_threshold','0');
% assume that noise has been whitened
setparamifndef('params.cbp.noise_sigma','1');
% CBP core interpolation
setparamifndef('params.cbp.cbp_core_fn','@polar_1D_cbp_core');
% Optimization solver function
setparamifndef('params.cbp.solve_fn','@cbp_ecos_2norm');
% MAX number of IRL1 iterations
setparamifndef('params.cbp.num_reweights','1e3');
% parallelization chunk size
setparamifndef('params.cbp.parfor_chunk_size','Inf');
% debug mode
setparamifndef('params.cbp.debug_mode','false');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CBP Outer (substage of CBP)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These parameters are for learning the waveforms.
% number of learning iterations
setparamifndef('params.cbp_outer.num_iterations','2e2');
% batch size for learning
setparamifndef('params.cbp_outer.batch_size','125');
% step size for updating waveform shapes
setparamifndef('params.cbp_outer.step_size','5e-2');
% annealing
setparamifndef('params.cbp_outer.step_size_decay_factor','1');
% plot interval
setparamifndef('params.cbp_outer.plotevery','1');
% stop when objective function increases
setparamifndef('params.cbp_outer.stop_on_increase','false');
% sanity check (true to be safe)
setparamifndef('params.cbp_outer.check_coeff_mtx','true');
% called each iteration to adjust waveform size
setparamifndef('params.cbp_outer.adjust_wfsize','@(w) w');
% always FALSE
setparamifndef('params.cbp_outer.rescale_flag','false');
% always FALSE
setparamifndef('params.cbp_outer.renormalize_features','false');
% always FALSE
setparamifndef('params.cbp_outer.reestimate_priors','false');
% convolves spikes w/waveforms
setparamifndef('params.cbp_outer.CoeffMtx_fn','@polar_1D_sp_cnv_mtx');
% plotting frequency
setparamifndef('params.cbp_outer.plot_every','1');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Amplitude Threshold stage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters for picking amplitude thresholds.
% Kernel density estimation parameters.
setparamifndef('params.amplitude.kdepoints','32');
setparamifndef('params.amplitude.kderange','[0.3 1.0]');
setparamifndef('params.amplitude.kdewidth','5');
% Histogram bins.
setparamifndef('params.amplitude.ampbins','60');
% Acceptable slack for considering two spikes a match. In units of samples.
% Currently two-sided, but this should probably be changed.
setparamifndef('params.amplitude.spike_location_slack','30');
% Number of simultaneous cells that can be plotted before using the scrollbar.
setparamifndef('params.amplitude.maxplotsbeforescroll','4');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





% Now we just put the parameter fields in the correct order
names = {'plotting', 'general', 'filtering', 'whitening', 'clustering', ...
         'partition', 'cbp', 'cbp_outer', 'amplitude'};
params = orderfields(params, names);

end

function setparamifndef(p_name, p_value)
    global params
    try
        eval([p_name ';']);
    catch
        eval([p_name ' = ' p_value ';']);
    end
end
