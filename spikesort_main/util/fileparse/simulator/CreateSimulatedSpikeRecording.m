% Creates a simulated spike recording.

function CreateSimulatedSpikeRecording
    global CBPdata params CBPInternals
    % loop each dialog until we get a valid answer
    
    % ask about number of channels
    while true
        try
            nchan = inputdlg("Please enter the number of channels: " + ...
                             "(4 is the recommended max)", ...
                             'Number of Channels', 1, {'4'});
            nchan = str2num(nchan{1});
            break;
        end
    end
    % This makes it so that the user isn't notified again about there being
    % too many channels in InitializeSession
    CBPInternals.skip_channel_message = true;

    % get number of neuron spike shapes
    while true
        try
            nspikes = inputdlg("Please enter the number of different neurons/spike waveforms. " + ...
                               "The max-abs of each waveform will be set to +/- 1.", ...
                               'Number of Spike Waveforms', 1, {'3'});
            nspikes = str2num(nspikes{1});
            break;
        end
    end
    

    % get std of noise
    while true
        try
            noisestd = inputdlg("Please enter the standard deviation of the noise, " + ...
                                "relative to a spike waveform max amplitude of 1. " + ...
                                "An std of .11 is similar to the ""Quiroga"" data set " + ...
                                "(value determined experimentally).", ...
                                'Noise Standard Deviations', 1, {'.11'});
            noisestd = str2num(noisestd{1});
            break;
        end
    end
    
    % get sample rate
    while true
        try
            fs = inputdlg('Please enter the sample rate, in Hz:', ...
                          'Sample Rate', 1, {'10000'});
            fs = str2num(fs{1});
            break;
        end
    end
    
    % get length of recording
    while true
        try
            time = inputdlg('Please enter the recording duration, in seconds:', ...
                            'Recording Duration (in seconds)', 1, {'30'});
            time = str2num(time{1});
            break;
        end
    end

    % set basic quantities to be reused
    waveform_len = 81;
    nsamples = fs * time;

    % randomly generate waveforms
    new_waveforms = {};
    waveform_offsets = [];
    for n = 1:nspikes
        new_waveform = [];
        for m = 1:nchan
            % on each channel:
            %   first generate white noise
            %   then lowpass filter w/ a Gaussian frequency response
            %   and also window w/ a Gaussian in time
            r = randn(1, waveform_len);
            r = real(ifft(fft(r).*fftshift(normpdf(-40:40,0,10)))).*normpdf(-40:40,0,4);
            new_waveform = [new_waveform;r];
        end

        % then, after doing the above, randomly blend some of each channel
        % to each other channel, so that each spike waveform appears on
        % more than one channel
        %
        % and normalize so that the max-abs sample value is 1
        mix_matrix = .5*randn(nchan) + .5*ones(nchan,nchan);
        mix_matrix = diag(randn(1,nchan)) * mix_matrix;
        new_waveform = mix_matrix*new_waveform;
        new_waveform = new_waveform';
        new_waveform = new_waveform/max(max(abs(new_waveform)));

        new_waveforms{n} = new_waveform;
    end
  
    % now, to prevent the various waveforms from being too similar to one
    % another, orthogonalize the waveform matrix, which means each waveform
    % is maximally far from the other ones
    %
    % first, get a column matrix of all flattened waveforms
    ortho_waveforms = [];
    for n=1:length(new_waveforms)
        ortho_waveforms(:, n) = new_waveforms{n}(:);
    end

    % there are two ways to do this: one is to orthogonalize all of the
    % waveforms as one flattened vector, and the other is to orthogonalize
    % each channel independently. The first seems to be giving better
    % results
    [ortho_waveforms, ~] = qr(ortho_waveforms, 0);
    % the orthogonalizing individual channels approach is below for
    % reference - doesn't seem to work as well
%     for n=1:nchan
%         start_ind = (n-1)*waveform_len + 1;
%         end_ind = start_ind + waveform_len - 1;
%         tmp_waveforms = ortho_waveforms(start_ind:end_ind, :);
%         [tmp_waveforms, ~] = qr(tmp_waveforms, 0);
%         ortho_waveforms(start_ind:end_ind, :) = tmp_waveforms;
%     end
    
    
    for n=1:length(new_waveforms)
        new_ortho_waveform = reshape(ortho_waveforms(:, n), ...
                               waveform_len, nchan);
        new_ortho_waveform = new_ortho_waveform/max(max(abs(new_ortho_waveform)));
        new_waveforms{n} = new_ortho_waveform;

        % get peak for each waveform
        waveform_peak_mix = max(abs(new_ortho_waveform), [], 2);
        waveform_offsets(n) = min(find(waveform_peak_mix == max(waveform_peak_mix)));
    end

    % create raw white noise
    noise = noisestd*randn(nchan, nsamples);


    % filter noise
    fnoise = [];
    for n=1:nchan
        fnoise = [fnoise;filter(1, [1 -0.75], noise(n,:))];
    end


    % create spike times so that the difference between spikes is randomly
    % distributed
    spike_time_array = {};
    for n=1:nspikes
        time_diffs = 900*exp(.8*randn(1,nsamples));
        time_diffs(time_diffs < 49) = [];
        
        % add an initial offset of 200 samples to everything so that we are sure
        % none of the spikes starts before the beginning of the waveform
        spike_time_array{n} = round(cumsum(time_diffs))+200;
        
        % likewise, remove any spikes after the end of the waveform
        spike_time_array{n} = spike_time_array{n}(spike_time_array{n} < nsamples - 200);
    end


    % combine into one sorted list
    combined_spike_time_array = [];
    for n=1:nspikes
        combined_spike_time_array = [combined_spike_time_array [spike_time_array{n};n*ones(1,length(spike_time_array{n}))]];
    end
    combined_spike_time_array = sortrows(combined_spike_time_array',1)';


    % initialize CBPdata and put into ground_truth object
    CBPdata = [];
    CBPdata.experiment_name = "Simulated Demo Data, "+nchan+" channels, " + ...
                             nspikes+" spike waveforms";
    CBPdata.raw_data = [];
    CBPdata.raw_data.data = [];
    CBPdata.raw_data.dt = 1/fs;
    CBPdata.ground_truth = [];
    CBPdata.ground_truth.true_spike_times = combined_spike_time_array(1,:);
    CBPdata.ground_truth.true_spike_class = combined_spike_time_array(2,:);
    CBPdata.ground_truth.true_spike_waveforms = new_waveforms;


    % create trace
    spike_traces = zeros(size(fnoise));
    for n=1:size(combined_spike_time_array,2)
        spikeclass = combined_spike_time_array(2,n);
        spiketime = combined_spike_time_array(1,n) - waveform_offsets(spikeclass);

        spike_traces(:,spiketime:spiketime+waveform_len-1) = ...
            spike_traces(:,spiketime:spiketime+waveform_len-1) + ...
            new_waveforms{spikeclass}';
    end


    % color the noise, create mixdown
    colmatrix = 1/9 + 5/9 * eye(nchan);
    colnoise = colmatrix * fnoise;
    colmix = spike_traces + colnoise;


    % add to CBPdata object
    CBPdata.raw_data.data = colmix;


    % set default parameters
    params = [];
    params.general.spike_waveform_len = waveform_len;
    params.filtering.freq = []; % no filtering by default, but [400 10000] also acceptable
    params.clustering.num_waveforms = nspikes;
end