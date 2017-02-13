function d = LoadRawData(identifier)
global params dataobj; %%@clean up globals

% Load raw electrode data from a file, and adjust any parameters
% that need to be specialized for that data set.  
%
% Data are assumed to be in a matlab (.mat) file, containing:
%   data: channel x time matrix of voltage traces
%   dt : the temporal sampling interval (in seconds)
% The file may optionally also contain:
%   averaging_method : determines how waveforms are aligned for clustering step:
%            maxrms : align wrt max L2 norm (RMS) value in segment
%            maxabs : align wrt max L1 norm value in segment
%            max : max signed sum across electrodes
%            min : min signed sum across electrodes
%%@         MIKE's note - L1, L2, Linf are really what we need
%   true_spike_times : vector of ground truth spike times, if known
%   true_spike_class : vector of numerical cell labels for each time
%%@
%%@ This takes in as input either a filename, or the two special values
%%@ 'Quiroga1' or 'Harris1', which load sample test data. If a filename is
%%@ entered, it should be a .mat file with at least "data" and "dt" loaded.
%%@ dt is the reciprocal of sample rate, and data is a matrix in which each
%%@ row represents one electrode.
%%@ BUG - averaging_method does not seem to be "optional"

switch identifier
    case 'Quiroga1'
        % Simulated data: single electrode.
        % From: Quiroga et. al., Neural Computation, 16:1661-1687, 2004.
        fprintf(1,'Loading Quiroga dataset 1...\n');
        filename = './example_data/C_Easy1_noise015.mat';
        d = load(filename, 'data', 'dt'); %%@dt is sampling rate

        d.averaging_method = 'max';
  
        params.filtering.freq = [];  % Low freq cutoff in Hz    

    case 'Harris1'
        % Real data: tetrode + one ground-truth intracellular electrode, rat hippocampus
        % From: Harris et. al., J. Neurophysiology, 84:401-414, 2000.
        fprintf(1,'Loading Harris dataset 1...\n');
        filename = './example_data/harris_d533101.mat';
        d = load(filename, 'data', 'dt');

        d.averaging_method = 'min';
   
        params.rawdata.waveform_len = 41;
        params.filtering.freq = [400 1e4];  % Low/high cutoff in Hz

    otherwise
        %%@New- Mike
        %Assume it's a file
        filename = identifier;
        fprintf(1,'Loading %s data...\n', filename);
        d = load(filename, 'data', 'dt');
        d.averaging_method = 'maxabs';
        %%@Do we need to do that here?
end

params.general.filename = filename;
d.filename = filename;
d.nchan = size(d.data, 1);
d.nsamples = size(d.data, 2);
d.processing = {};

fprintf (1, '  ... %d sec (%.1f min) of voltage data at %.1f kHz on %d channel(s).\n', ...
	 round(d.nsamples*d.dt), ...
	 (d.nsamples*d.dt/60), ...
	 1/(d.dt*1000), ...
	 d.nchan);

if (d.dt > 1/5000)
  warning('Sampling rate is %.1f kHz, but recommended minimum is 5kHz', 1/(1000*d.dt)); 
end

%%@Diagnostic plotting used to be here, but has been split into its own
%file
end