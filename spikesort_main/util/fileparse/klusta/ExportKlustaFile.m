% Exporter that writes the current raw electrode data, as well
% as the filtered and/or whitened data (if it exists), to a .dat file (same
% as ExportRawDataFile), and also writes the current parameters (if
% relevant) to the corresponding .prm file.
%
% See ExportRawDataFile.m for more information on how the .dat file is
% structured.

function ExportKlustaFile(filename, use_their_defaults)
    global CBPdata params;
    
    %%@ for now just always set this to true.
    if nargin < 2
        use_their_defaults = true;
    end

    % let user know about folder
    waitfor(msgbox("You have chosen to export to the klusta data format. This " + ...
                   "exporter *only* saves the raw/filtered/whitened data, " + ...
                   "and whatever accompanying parameters match klusta's " + ...
                   ".prm format, but not any of the clustering or CBP results. " + ...
                   "Filtered/whitened data will only be saved if the relevant " + ...
                   "stage has been done.", ...
                   "Exporting Klusta.", "help", "modal"));

    % assert raw data exists
    assert(isfield(CBPdata, "raw_data"), "ExportKlustaFile: CBPdata.raw_data doesn't exist!");
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write .dat file. This is currently just duplicated from
% ExportRawDataFile, but it's pretty small, so alright
    % create some convenient local variables
    [dir, name_no_ext, ext] = fileparts(filename);
    fileprefix = dir + "/" + name_no_ext;
    
    % Save raw data
    if isfield(CBPdata, "raw_data")
        writedata(fileprefix + "_raw.dat", CBPdata.raw_data);
    end
    if isfield(CBPdata, "filtering")
        writedata(fileprefix + "_filt.dat", CBPdata.filtering);
    end
    if isfield(CBPdata, "whitening")
        writedata(fileprefix + "_filtwhite.dat", CBPdata.whitening);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write .prm file.
    prm_out = "";
    
% Header
%     % experiment name and prb file. prb file is auto-generated and just has
    % each electrode connected to every other
    prm_out = prm_out + ...
        "experiment_name = '" + name_no_ext + "'" + newline + ...
        "prb_file = '" + name_no_ext + ".prb'" + newline + ...
        newline;
    
% Traces Dict
    prm_out = prm_out + "traces = dict(" + newline;
    
    % raw_data_files
    % first get latest stage (whitening? filtering? etc)
    data_file = "";
    if isfield(CBPdata, "whitening")
        data_file = name_no_ext + "_filtwhite.dat";
    elseif isfield(CBPdata, "filtering")
        data_file = name_no_ext + "_filt.dat";
    elseif isfield(CBPdata, "raw_data")
        data_file = name_no_ext + "_raw.dat";
    end
    prm_out = prm_out + ...
        writedict("raw_data_files", "['" + data_file+ "']", "raw");  
    
    % voltage_gain (should be the thing you multiplied the actual voltage
    % by to get the stored data). So, if the stored data goes to +/- 1, and
    % the original data was +/- 10µV, voltage_gain would be 10e6 (=
    % 1/10e-6). We aren't currently gathering this information for
    % raw data, so just treat the voltage_gain as unity until we get to the
    % filtering stage, where we scale it to normalize the mad
    voltage_gain = 1;
    if isfield(CBPdata, "filtering") && ...
            isfield(CBPdata.filtering, "trimmed_mad")
        voltage_gain = 1/CBPdata.filtering.trimmed_mad;
    end
    prm_out = prm_out + ...
        writedict("voltage_gain", voltage_gain, "double");
    
    % sample_rate (use whitening rate if possible)
    sample_rate = "";
    if isfield(CBPdata, "whitening")
        sample_rate = round(1/CBPdata.whitening.dt);
    elseif isfield(CBPdata, "filtering")
        sample_rate = round(1/CBPdata.filtering.dt);
    elseif isfield(CBPdata, "raw_data")
        sample_rate = round(1/CBPdata.raw_data.dt);
    end
    prm_out = prm_out + ...
        writedict("sample_rate", sample_rate, "int");
    
    % n_channels (use whitening nchan if possible)
    n_channels = "";
    if isfield(CBPdata, "whitening")
        n_channels = CBPdata.whitening.nchan;
    elseif isfield(CBPdata, "filtering")
        n_channels = CBPdata.filtering.nchan;
    elseif isfield(CBPdata, "raw_data")
        n_channels = CBPdata.raw_data.nchan;
    end
    prm_out = prm_out + ...
        writedict("n_channels", n_channels, "int");
    
    % d_type
    %%@ just hard-code int16 for now, which seems to be the standard
    %%@ klusta dtype
    d_type = "int16";
    prm_out = prm_out + ...
        writedict("dtype", d_type);
    
    % Close traces dict
    prm_out = prm_out + ")" + newline;
    prm_out = prm_out + newline;
    

% Spikedetekt Dict
% Documentation for how their parameters relate to ours is in
% ParseKlustaFile.m
% If use_their_defaults is selected, we use the defaults from
% https://github.com/klusta-team/example/blob/master/params.prm
% - which may be better suited for their algorithm than ours!
    prm_out = prm_out + "spikedetekt = dict(" + newline;
    
    
    % filter_low, filter_high_factor, filter_butter_order
    % check that filtering exists!
    %%@ NOTE: sometimes it uses filter_high and sometimes
    %%@ filter_high_factor?
    if use_their_defaults
%         filter_low = 500;
%         filter_high = 0.95 * .5 * sample_rate;
%         prm_out = prm_out + ...
%             writedict("filter_low", filter_low, "double");  
%         prm_out = prm_out + ...
%             writedict("filter_high", filter_high, "double");  
    else
        if isempty(params.filtering.freq)
            filter_low = 0;
            filter_high = 0.5 * sample_rate;
        else
            filter_low = params.filtering.freq(0);
            filter_high = params.filtering.freq(1);
        end
        prm_out = prm_out + ...
            writedict("filter_low", filter_low, "double");  
        prm_out = prm_out + ...
            writedict("filter_high", filter_high, "double");  
    end

    

    % chunk_size_seconds, chunk_overlap_seconds
    if use_their_defaults
%         chunk_size = round(1. * sample_rate);
%         chunk_overlap = round(.015 * sample_rate);
%         prm_out = prm_out + ...
%             writedict("chunk_size", chunk_size, "int");  
%         prm_out = prm_out + ...
%             writedict("chunk_overlap_seconds", chunk_overlap, "int");
    else
        % Go with our parfor_chunk_size, but since we have no
        % "chunk_overlap," go with their default of 1.5% of the chunk size
        chunk_size = round(params.cbp.parfor_chunk_size / samplerate);
        chunk_overlap = round(.015 * chunk_size);
        prm_out = prm_out + ...
            writedict("chunk_size", chunk_size, "int");  
        prm_out = prm_out + ...
            writedict("chunk_overlap_seconds", chunk_overlap, "int");
    end



    % detect_spikes
    % Our simulator can output both "positive" and "negative" spikes and
    % only looks at the Linf norm, so set this to both
    prm_out = prm_out + ...
        writedict("detect_spikes", "both");  
    
    
    % n_excerpts, excerpt_size_seconds
    % We don't use either of these, so just go with their defaults
%     n_excerpts = 50;
%     excerpt_size = round(sample_rate);
%     prm_out = prm_out + ...
%         writedict("n_excerpts", n_excerpts, "int");  
%     prm_out = prm_out + ...
%         writedict("excerpt_size", excerpt_size, "int");
    
    
    % threshold_strong_std_factor, threshold_weak_std_factor
    if use_their_defaults
%         threshold_strong_std_factor = 4;
%         threshold_weak_std_factor = 2;
%         prm_out = prm_out + ...
%             writedict("threshold_strong_std_factor", ...
%                       threshold_strong_std_factor, "double");
%         prm_out = prm_out + ...
%             writedict("threshold_weak_std_factor", ...
%                       threshold_weak_std_factor, "double");
    else
        threshold_strong_std_factor = params.clustering.spike_threshold;
        threshold_weak_std_factor = params.partition.silence_threshold;
        prm_out = prm_out + ...
            writedict("threshold_strong_std_factor", ...
                      threshold_strong_std_factor, "double");
        prm_out = prm_out + ...
            writedict("threshold_weak_std_factor", ...
                      threshold_weak_std_factor, "double");
    end

    
    % extract_s_before, extract_s_after
    if use_their_defaults
%         extract_s_before = 16;
%         extract_s_after = 16;
%         prm_out = prm_out + ...
%             writedict("extract_s_before", extract_s_before, "double");
%         prm_out = prm_out + ...
%             writedict("extract_s_after", extract_s_after, "double");
    else
        extract_s_before = (params.general.spike_waveform_len-1)/2;
        extract_s_after = (params.general.spike_waveform_len-1)/2;
        prm_out = prm_out + ...
            writedict("extract_s_before", extract_s_before, "double");
        prm_out = prm_out + ...
            writedict("extract_s_after", extract_s_after, "double");
    end

    
    % n_features_per_channel
    % I don't have any documentation on what this is, so we'll just ignore
    % it.
    % pca_n_waveforms_max
    
    % Close Spikedetekt dict
    prm_out = prm_out + ")" + newline;
    prm_out = prm_out + newline;


% KlustaKwik2 Dict
% Seems to only be used for the starting number of clusters!
% https://github.com/klusta-team/example/blob/master/params.prm
    prm_out = prm_out + "klustakwik2 = dict(" + newline;
    
    prm_out = prm_out + ...
        writedict("num_starting_clusters", ...
                  params.clustering.num_waveforms, "int");
              
    % Close KlustaKwik2 dict
    prm_out = prm_out + ")" + newline;

    f_prm = fopen(fileprefix + ".prm", "w+");
    fwrite(f_prm, prm_out);
    fclose(f_prm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Write .prb file.
    
% Start with the number of channels and have everything be connected
    prb_out = "channel_groups = {" + newline;
    prb_out = prb_out + ...
        "    0: {" + newline;

    % Now add channels
    list_of_channels = strjoin(string(0:n_channels-1), ', ');
    prb_out = prb_out + ...
        "        'channels': [" + list_of_channels + "]," + newline;

    % Now add geometry
    prb_out = prb_out + ...
        "        'geometry': {" + newline;

    for n=0:n_channels-1
        prb_out = prb_out + ...
            "            " + n + ": (0, " + 10*n + ")," + newline;
    end

    % Now close all the braces and write everything
    prb_out = prb_out + ...
        "        }" + newline;
    prb_out = prb_out + ...
        "    }" + newline;
    prb_out = prb_out + ...
        "}" + newline;

    f_prb = fopen(fileprefix + ".prb", "w+");
    fwrite(f_prb, prb_out);
    fclose(f_prb);

end

% just returns a line in the dictionary
function out = writedict(name, val, type)
    if nargin < 3
         % this is only used if val isn't a string or char array
        type = "double";
    end
    
    out = name + "=";

    if type == "raw"
        % if raw, we're just writing the exact value of "val" (assumed to be a
        % string)
        out = out + val;
    elseif isa(val, "string") || isa(val, "char")
        % if not raw, and if it's a string, put it in quotes and escape
        % inner quotes
        val = strrep(val, "\", "\\");   % escape slashes
        val = strrep(val, "'", "\'");   % escape quotes
        out = out + "'" + val + "'";
    elseif type == "double"
        % if double, just export as-is, but add a trailing "." if needed
        out = out + num2str(val);
        if ~contains(num2str(val), ".")
            out = out + ".";
        end
    elseif type == "int"
        % if int, just export without any trailing anything
        assert(val == round(val), ...
            "Error in writedict: 'int' type must round to itself");
        out = out + num2str(val);
    end
    out = "    " + out + "," + sprintf("\n");
end