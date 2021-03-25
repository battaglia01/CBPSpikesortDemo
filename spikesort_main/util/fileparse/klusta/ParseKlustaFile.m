% Parses a Klusta .prm file, which imports the associated raw data and
% uses the .prm file to auto-set our parameters.
% Reference prm at https://github.com/klusta-team/example/blob/master/params.prm
function ParseKlustaFile(filename)
    global CBPdata params CBPInternals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BASICS

    % get path from filename. strange way of doing it, but c'est la
    % matlab...
    f = fopen(filename);
    fullname = fopen(f);
    fclose(f);
    pathname = fileparts(fullname);

    % read the code and parse via Python's parser. Stores the resulting
    % variables in our "py_env" dictionary. Pop the extraneous
    % "__builtins__" thing
    try
        py_env = py.dict;
        py_code = fileread(filename);
        py.eval(py.compile(py_code,'asdf','exec'),py_env)
        py_env.pop('__builtins__');
    catch err
        error("Error parsing " + filename + ". Is this Python file malformed?");
    end

    % Convert from python dictionary to our CBPdata/params format
    CBPdata = [];
    params = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% METADATA

    % add notes about the import
    CBPdata.importnotes = [];
    CBPdata.importnotes.note = 'Imported from Klusta PRM file';
    CBPdata.importnotes.origfile = filename;
    CBPdata.importnotes.origparams = py_env;

    CBPdata.experiment_name = char(py_env.get('experiment_name'));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ DATA FILE AND CONCATENATE
    %
    % "traces" dict:
    %   raw_data_files -> CBPdata.raw_data.data (concatenate)
    %   1/sample_rate -> CBPdata.raw_data.dt
    %   n_channels -> nothing (num of columns in CBPdata.raw_data.data)
    %   dtype -> nothing, just used internally for file parsing
    %   voltage_gain -> nothing -- just wastes precision as we rescale anyway

    % get raw_data - make sure file is there, and all metadata is present
    CBPdata.raw_data = [];
    assertKeyExists(py_env, 'traces/raw_data_files', ...
                    'ERROR: traces.raw_data_files missing!');
    assertKeyExists(py_env, 'traces/sample_rate', ...
                    'ERROR: traces.sample_rate missing!');
    assertKeyExists(py_env, 'traces/n_channels', ...
                    'ERROR: traces.n_channels missing!');
    assertKeyExists(py_env, 'traces/dtype', 'ERROR: traces.dtype missing!');

    % read file. cd into the path to avoid relative path issues, return
    % later
    old_dir = pwd;
    cd(pathname);

    files_to_read_py = getKey(py_env, 'traces/raw_data_files');
    datatype = getKey(py_env, 'traces/dtype', 'char');
    n_channels = getKey(py_env, 'traces/n_channels', 'double');
    CBPdata.raw_data.data = [];
    %%@ NOTE - this could be put into its own "readRAW" file or something,
    %%@ but some of this may be particular to Python
    for fname_py = files_to_read_py
        % NOTE: this is a "one-element list of Python string type", so we
        % convert to MFATLAB chararray
        fname = char(fname_py{1});
        assert(isfile(fname), "ERROR: referenced file '" + fname + ...
                              "' doesn't exist!");
        newdata = UnserializeRawDataFromFile(fname, datatype, n_channels);
        CBPdata.raw_data.data = [CBPdata.raw_data.data newdata];
        fclose(f);
    end
    cd(old_dir);

    CBPdata.raw_data.dt = 1/getKey(py_env, 'traces/sample_rate', 'double');
    CBPdata.raw_data.nchan = n_channels;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% "SPIKEDETEKT" PARAMS

    % Preliminary convenience variables
    samplerate = getKey(py_env, 'traces/sample_rate', 'double');

    % Structure of "spikedetekt" dictionary:
    %
    % Filtering:
    %	filter_low: params.filtering.freq(1)
    %   filter_high_factor: params.filtering.freq(2) (multiply by sample
    %                       rate)
    %   filter_butter_order: params.filtering.order
    %                        (set filtering.type to "butter")
    params.filtering = [];
    freq = [0];
    if keyExists(py_env, 'spikedetekt/filter_low')
        freq(1) = getKey(py_env, 'spikedetekt/filter_low', 'double');
    end
    if keyExists(py_env, 'spikedetekt/filter_high_factor')
        freq(2) = getKey(py_env, 'spikedetekt/filter_high_factor', ...
                         'double') * samplerate;
    end
    if ~isequal(freq, [0])
        params.filtering.freq = freq;
    end

    if keyExists(py_env, 'spikedetekt/filter_butter_order')
        params.filtering.type = 'butter';
        params.filtering.order = getKey(py_env, ...
            'spikedetekt/filter_butter_order', 'double');
    end

    % Data chunks
    %   chunk_size_seconds * samplerate -> params.cbp.parfor_chunk_size
    %	chunk_overlap_seconds -> NOT IMPLEMENTED
    if keyExists(py_env, 'spikedetekt/chunk_size_seconds')
        chunks = getKey(py_env, 'spikedetekt/chunk_size_seconds', ...
                        'double');
        params.cbp.parfor_chunk_size = round(chunks * samplerate);
    end
    % NOTE - this has a "chunk_overlap_seconds" parameter too, which we
    % don't seem to use...


    % Thresholds
    %   n_excerpts -> NOT IMPLEMENTED (part of their white noise detection)
    %   excerpt_size_seconds -> NOT IMPLEMENTED (likewise)
    %   threshold_strong_std_factor -> params.clustering.spike_threshold
    %
    %   threshold_weak_std_factor ->   params.partition.silence_threshold
    %
    %   use_single_threshold -> assume the weak one is 80% of the strong
    %                           one for CBP's default
    %   if only one std is set but not use_single_threshold, set to strong
    %   detect_spikes -> NOT IMPLEMENTED (sets asymmetry in positive/
    %                                    negative spike detection)
    %
    % Note that there is nothing here corresponding to
    % params.whitening.noise_threshold. I am not sure exactly how to import
    % that! We will just leave that at the default and let the user adjust.
    if keyExists(py_env, 'spikedetekt/threshold_strong_std_factor')
        strong_s = getKey(py_env, 'spikedetekt/threshold_strong_std_factor',...
                          'double');
        params.clustering.spike_threshold = strong_s;
    end

    % check if use_single_threshold is set before setting the weak
    % threshold
    use_single_threshold = false;
    if keyExists(py_env, 'spikedetekt/use_single_threshold')
        use_single_threshold = ...
            getKey(py_env, 'spikedetekt/use_single_threshold', 'logical');
    end

    % If use_single_threshold isn't true and key exists, set the silence
    % threshold to the weak threshold. If not, and if the strong threshold
    % is set, set the weak threshold 80% of the strong threshold. Otherwise
    % just leave everything unset.
    if ~use_single_threshold && keyExists(py_env, 'spikedetekt/threshold_weak_std_factor')
        weak_s = getKey(py_env, 'spikedetekt/threshold_weak_std_factor',...
                        'double');
        %%@ NOTE - doesn't wokr well. Just don't set this at all
        %params.partition.silence_threshold = weak_s;
    elseif keyExists(py_env, 'spikedetekt/threshold_weak_std_factor') && ...
           ~keyExists(py_env, 'spikedetekt/threshold_strong_std_factor')
        % if we've gotten here, then strong_std_factor isn't set but
        % weak_std_factor is, and there is only one threshold. Probably a
        % param formatting error - so just treat this as the *strong*
        % threshold.
        weak_s = .8 * getKey(py_env, 'spikedetekt/threshold_strong_std_factor',...
                             'double');
        params.clustering.spike_threshold = weak_s;
    end


    % Connected Components
    %   connected_component_join_size -> NOT IMPLEMENTED, I don't think.

    % Spike Extractions
    %   extract_s_before -> params.general.spike_waveform_len
    %   extract_s_after -> params.general.spike_waveform_len
    %                   (our version is symmetrical - take max of both,
    %                    multiply by 2 and add 1)
    %   weight_power -> NOT IMPLEMENTED (p-norm, we always do RMS)
    if keyExists(py_env, 'spikedetekt/extract_s_before') || ...
       keyExists(py_env, 'spikedetekt/extract_s_after')
        before = getKey(py_env, 'spikedetekt/extract_s_before', 'double');
        after = getKey(py_env, 'spikedetekt/extract_s_after', 'double');
        waveformlen = max([before after])*2+1;
        params.general.spike_waveform_len = waveformlen;
    end


    % Features -- related to PCA?
    %    n_features_per_channel: %%@IGNORE UNTIL I KNOW WHAT FEATURES ARE
    %    pca_n_waveforms_max: %%@IGNORE UNTIL I KNOW WHAT FEATURES ARE

    % KlustaKwik2 params
    %   num_starting_clusters -> params.clustering.num_waveforms
    %                            (note GUI is glitchy if this is too high)
    if keyExists(py_env, 'klustakwik2/num_starting_clusters')
        params.clustering.num_waveforms = getKey(py_env, ...
            'klustakwik2/num_starting_clusters', 'double');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLEANUP

    % reorder field names in CBPdata and params
    CBPfields = {'filename', 'experiment_name', 'importnotes', ...
                 'raw_data', 'filtering', 'whitening', 'clustering', ...
                 'CBP', 'amplitude', 'clusteringcomparison', ...
                 'sonification'};
    parfields = {'plotting', 'general', ...
                 'filtering', 'whitening', 'clustering', ...
                 'partition', 'cbp', 'cbp_outer', ...
                 'amplitude'};

    % remove extra fields that we don't have, preserving the ordering
    currCBPfields = {};
    currparfields = {};
    for n=CBPfields
        if ismember(n, fieldnames(CBPdata))
            currCBPfields(end+1) = n;
        end
    end
    for n=parfields
        if ismember(n, fieldnames(params))
            currparfields(end+1) = n;
        end
    end

    CBPdata = orderfields(CBPdata, currCBPfields);
    params = orderfields(params, currparfields);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLUSTERING
    %
    % If the "kwik" file is found, corresponding to the filename referenced
    % in the .prm file, we will also fill all of the fields up to the
    % InitializeWaveform stage. Since there is no Whitening, and we may not
    % have access to the raw data, we will just use the main data set for
    % all three initial stages with zero filtering and an identity
    % whitening matrix.
    filename_kwik = pathname + "/" + CBPdata.experiment_name + ".kwik";
    if isfile(filename_kwik)
        % First, fill in default parameters (although we will probably be
        % filling in anyway!
        params.filtering.freq = [];
        FillInDefaultParameters;
%
%         % Now, turn off calibration mode and run up to the Whitening Stage,
%         % to auto-populate that data
%         params.plotting.calibration_mode = false;
%         InitializeSession(filename);
%         CBPStage("RawData");
%         CBPStage("Filter");
%         CBPStage("Whiten");
%         CBPInternals.already_initialized_session = true;
%
%         % Now, also manually shift the internals *as though* we'd processed
%         % the Initialize Waveform stage, without really having to do it
%         CBPInternals.most_recent_stage = GetStageFromName("InitializeWaveform");
%         CBPInternals.curr_selected_tab_stage = GetStageFromName("InitializeWaveform");
%         CBPdata.last_stage_name = "InitializeWaveform";
%
%         % set calibration mode back
%         params.plotting.calibration_mode = true;


        % Now populate CBPdata.external data with the data from the
        % "klustering." First get all channel groups
        ch_grp_h5 = h5info(filename_kwik, "/channel_groups/");
        ch_grp_list = {ch_grp_h5.Groups.Name};

        % Now, for each channel group, get the clusters for that group.
        % These are cell arrays of arrays, each entry corresponding to the cluster
        % information for a particular "channel group."
        %
        % We start with segment_centers and assignments, and then from there we
        % build X and the centroids, and then XProj and the PCs. We also adjust the
        % cluster ID #'s at the end.
        segment_centers = {};
        assignments = {};
        current_group_index = 1;
        for n=1:length(ch_grp_list)
            % current channel group name
            ch_grp_name = ch_grp_list{n};

            % h5 object for the above group name
            ch_grp_h5 = h5info(filename_kwik, ch_grp_name);

            % channel object for the above group
            channels_h5 = h5info(filename_kwik, ch_grp_name + "/channels");

            % list of channels for this current group
            channels = {channels_h5.Groups.Name};
            channels = cellfun(@(x) str2num(x(end)), channels) + 1;

            segment_centers{current_group_index} = ...
                double(h5read(filename_kwik, ch_grp_name + "/spikes/time_samples"));
            assignments{current_group_index} = ...
                    double(h5read(filename_kwik, ch_grp_name + "/spikes/clusters/main"));

            % increment group index
            current_group_index = current_group_index + 1;
        end

        % Now, at this point, we have a cell array of arrays of spike times and
        % corresponding assignments, one for each group. The assignments may not
        % all be taken, so first we make sure that the first entry in the cell
        % array has assignments 1-N taken, and then N+1-M, and so on.
        %%@ code reused from MergeClusters; may be good to make into a reusable
        %%function
        % redo assignment numbers
        for l=1:length(assignments)
            % next_num = 1;
            % for n=1:max(assignments{l})
            %     assignment_inds = find(assignments{l} == n);
            %     if ~isempty(assignment_inds)
            %         assignments{l}(assignment_inds) = next_num;
            %         next_num = next_num + 1;
            %     end
            % end
            assignments{l} = CleanUpAssignmentNumbers(assignments{l});
        end

        % Now, we also adjust the indices so that each successive cell array entry
        % builds on the last one
        last_entry = 0;
        for l=1:length(assignments)
            assignments{l} = assignments{l} + last_entry;
            last_entry = max(assignments{l});
        end

        % Add fields to CBPdata
        CBPdata.external = [];
        CBPdata.external.segment_centers = vertcat(segment_centers{:});
        CBPdata.external.assignments = vertcat(assignments{:});

        % Now adjust the number of waveforms
        params.clustering.num_waveforms = last_entry;
            %
            % [CBPdata.external.X, CBPdata.external.centroids, ...
            %  CBPdata.external.assignments, CBPdata.external.PCs, ...
            %  CBPdata.external.XProj, CBPdata.external.init_waveforms, ...
            %  CBPdata.external.spike_time_array_cl] = ...
            %     GetAllSpikeInfo(...
            %         CBPdata.external.segment_centers, ...
            %         CBPdata.external.assignments);

%         % lastly, reorganize the CBPdata fields
%         CBPdata.external = orderfields(CBPdata.external, ...
%             ["centroids", "assignments", "X", "XProj", "PCs", ...
%              "segment_centers", "init_waveforms", "spike_time_array_cl"]);

        % reset number of passes
        % CBPdata.CBP.num_passes = 0;

        % Now begin the session
                % InitializeSession(filename);
                % CBPStage("RawData");
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GROUND TRUTH
    %
    % If a ".mat" file is found in the same directory with the same name,
    % then we check it for ground truth information (we then assume this
    % was exported from CBP/MATLAB to begin with)
    filename_mat = [filename(1:end-4) '.mat'];
    if isfile(filename_mat)
        tmp_load = load(filename_mat, "CBPdata");
        CBPdata.ground_truth = tmp_load.CBPdata.ground_truth;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPER FUNCTIONS

function out = getKey(env, identifier, format)
    out = env;
    keys = strsplit(identifier,'/');
    for key = keys
        out = out.get(key{1});
        if isa(out, 'py.NoneType')
            break; % end the loop here; don't call get() again
        end
    end

    if nargin > 2
        if isa(out, 'py.NoneType')
            out = cast([], format);
        else
            out = cast(out, format);
        end
    end
end

function out = keyExists(env, identifier)
    out = ~isa(getKey(env, identifier), 'py.NoneType');
end

function assertKeyExists(env, identifier, errormsg)
    assert(keyExists(env, identifier), errormsg);
end
