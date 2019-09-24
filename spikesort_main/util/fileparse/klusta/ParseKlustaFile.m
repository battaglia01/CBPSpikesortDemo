% Parses a Klusta .prm file.
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
    py_env = py.dict;
    py_code = fileread(filename);
    py.eval(py.compile(py_code,'asdf','exec'),py_env)
    py_env.pop('__builtins__');

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

    CBPdata.experimentname = char(py_env.get('experiment_name'));


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % READ DATA FILE AND CONCATENATE
    %
    % "traces" dict:
    %   raw_data_files -> CBPdata.rawdata.data (concatenate)
    %   1/sample_rate -> CBPdata.rawdata.dt
    %   n_channels -> nothing (num of columns in CBPdata.rawdata.data)
    %   dtype -> nothing, just used internally for file parsing
    %   voltage_gain -> nothing -- just wastes precision as we rescale anyway

    % get rawdata - make sure file is there, and all metadata is present
    CBPdata.rawdata = [];
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
    CBPdata.rawdata.data = [];
    %%@ NOTE - this could be put into its own "readRAW" file or something,
    %%@ but some of this may be particular to Python
    for fname_py = files_to_read_py
        % NOTE: this is a "one-element list of Python string type", so we
        % convert to MFATLAB chararray
        fname = char(fname_py{1});
        assert(isfile(fname), "ERROR: referenced file '" + fname + ...
                              "' doesn't exist!");
        newdata = UnserializeRawDataFromFile(fname, datatype, n_channels);
        CBPdata.rawdata.data = [CBPdata.rawdata.data newdata];
        fclose(f);
    end
    cd(old_dir);

    CBPdata.rawdata.dt = 1/getKey(py_env, 'traces/sample_rate', 'double');
    CBPdata.rawdata.nchan = n_channels;


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
    %
    % Thresholds
    %   n_excerpts -> NOT IMPLEMENTED (part of their white noise detection)
    %   excerpt_size_seconds -> NOT IMPLEMENTED (likewise)
    %   threshold_strong_std_factor -> params.clustering.spike_threshold
    %                                  params.partition.silence_threshold
    %                                  (both are basically the strong
    %                                  threshold)
    %   threshold_weak_std_factor ->   unsure if anything. setting either
    %                                  of the above variables to this
    %                                  instead of the strong factor gives
    %                                  weird results.
    %                                  params.cbp.magnitude_threshold
    %                                  also doesn't work if set to this.
    %   use_single_threshold -> leave the weak one unset
    %   if only one std is set but not use_single_threshold, set to strong
    %   detect_spikes -> NOT IMPLEMENTED (sets asymmetry in positive/
    %                                    negative spike detection)

    if keyExists(py_env, 'spikedetekt/threshold_strong_std_factor')
        strong_s = getKey(py_env, 'spikedetekt/threshold_strong_std_factor',...
                          'double');
        params.clustering.spike_threshold = strong_s;
        params.partition.silence_threshold = strong_s;
    elseif keyExists(py_env, 'spikedetekt/threshold_weak_std_factor')
        % if we've gotten here, then strong_std_factor isn't set but
        % weak_std_factor is, and there is only one threshold. Probably a
        % param formatting error - so just treat this as the *strong*
        % threshold.
        weak_s = getKey(py_env, 'spikedetekt/threshold_strong_std_factor',...
                          'double');
        params.clustering.spike_threshold = weak_s;
        params.partition.silence_threshold = weak_s;
    end
    % if we've gotten this far, neither strong or weak thresholds were set,
    % go with CBP defaults.


    % Connected Components
    %   connected_component_join_size -> NOT IMPLEMENTED, I don't think.

    % Spike Extractions
    %   extract_s_before -> params.rawdata.waveform_len
    %   extract_s_after -> params.rawdata.waveform_len
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
    %    n_features_per_channel: IGNORE UNTIL I KNOW WHAT FEATURES ARE
    %    pca_n_waveforms_max: IGNORE UNTIL I KNOW WHAT FEATURES ARE

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
    CBPfields = {'filename', 'experimentname', 'importnotes', ...
                 'rawdata', 'filtering', 'whitening', 'clustering', ...
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