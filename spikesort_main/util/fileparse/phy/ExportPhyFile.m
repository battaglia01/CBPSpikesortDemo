% Exporter that writes the current CBP results to the Phy npy format.
% Note that this creates a folder for the filename the user entered.
% Note that the user has probably typed a *.npy name in, so we should let them
% know that this will create a folder instead.
function ExportPhyFile(filename)
    global CBPdata params;

    % first, make sure writeNPY exists
    if ~exist("writeNPY")
        error("To export to Phy format, the npy-matlab repository needs to " + ...
              "be installed and on the path. This can be downloaded from " + ...
              "https://github.com/kwikteam/npy-matlab. Please install " + ...
              "and try again!");
    end
    % first, check that we've gotten at least to the waveform refinement stage
    if ~isfield(CBPdata, 'waveformrefinement')
        error("You need to get to at least the 'Waveform Refinement' " + ...
              "stage before exporting to Phy format. Please continue " + ...
              "through the CBP stages, or export to a different format.");
    else
        % let user know about folder
        waitfor(msgbox("You have chosen to export to Phy. This will automatically " + ...
                       "create a subfolder with the relevant .npy files in it.", ...
                       "Exporting to Phy", "help", "modal"));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BASIC SETUP, FOLDER CREATION
    % create some convenient local variables
    [dir, name, ext] = fileparts(filename);
    filedir = dir + "/" + name;
    nchan = CBPdata.whitening.nchan;
    spike_times_thresholded = CBPdata.waveformrefinement.spike_times_thresholded;
    spike_amps_thresholded = CBPdata.waveformrefinement.spike_amps_thresholded;
    final_waveforms = CBPdata.waveformrefinement.final_waveforms;

    % create an entire folder with the entered filename. So if they entered
    % mydata.npy, make "mydata" the foldername, with subfiles
    mkdir(filedir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WRITE SAMPLE DATA, PARAMS, CHANNEL MAP
    % WRITE WHITENED DATA TO rawdata.dat. For now, just do int16 (can
    % change this if need be.
    %
    % Since we're doing int16, and whitened data is floating point, we need
    % to scale this.
    % Scale it so that the largest sample is stored to +/- 65536, and store
    % the scale factor for later.
    %
    scalefactor = norm(CBPdata.whitening.data(:),Inf);
    scaledwhitened = round(CBPdata.whitening.data * 32767/scalefactor);
    f = fopen(filedir + "/filtered_whitened.dat", "w");
    fwrite(f, scaledwhitened(:), "int16");
    fclose(f);

    % params.py - text file that specifies:
    %   dat_path - location of raw data file
    %   n_channels_dat - total number of rows in the data file (not
    %                    just those that have your neural data on
    %                    them. This is for loading the file)
    %   dtype - data type to read, e.g. 'int16'
    %   offset - number of bytes at the beginning of the file to skip
    %   sample_rate - in Hz
    %   hp_filtered - True/False, whether the data have already been
    %                 filtered
    f = fopen(filedir + "/params.py", "w");
    fwrite(f, sprintf("dat_path = 'filtered_whitened.dat'\n"));
    fwrite(f, sprintf("n_channels_dat = " + CBPdata.rawdata.nchan + "\n"));
    fwrite(f, sprintf("dtype = 'int16' \n"));
    fwrite(f, sprintf("offset = 0\n"));
    fwrite(f, sprintf("sample_rate = " + round(1/CBPdata.rawdata.dt) + ".\n"));
    fwrite(f, sprintf("hp_filtered = True\n"));
    fclose(f);

    % channel_map.npy - [nChannels, ] int32 vector with the channel map, i.e. which row of the data file to look in for the channel in question
    %   (this is just 0:nChannels-1)
    writeNPY(int32(0:(nchan-1)), filedir + "/channel_map.npy");

    % channel_positions.npy - [nChannels, 2] double matrix with each row giving the x and y coordinates of that channel. Together with the channel map, this determines how waveforms will be plotted in WaveformView (see below).
    %   (ycoords just increasing by 20, xcoords staggered between 0 and 20)
    xcoords = zeros(nchan,1);
    ycoords = 20*[0:(nchan-1)]';    %%@ 20px hardwired in for now
    writeNPY([xcoords ycoords], filedir + "/channel_positions.npy");

    % whitening_mat.npy - [nChannels, nChannels] double whitening matrix applied to the data during automatic spike sorting
    writeNPY(sqrtm(inv(CBPdata.whitening.old_cov)), filedir + "/whitening_mat.npy");

    % whitening_mat_inv.npy - [nChannels, nChannels] double, the inverse of the whitening matrix.
    writeNPY(inv(CBPdata.whitening.old_cov), filedir + "/whitening_mat_inv.npy");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SPIKE TIMING/AMPLITUDE INFO
    % first we need to collate all the spikes into one huge array. The first row
    % will be the waveform ID number, the second will be the time (in samples),
    % the third will be the amplitude.
    % we will offset each spike ID by 1, so the first spike is #0.
    % we will also sort so they are in ascending time order
    allspikes = [];
    for n=1:length(spike_times_thresholded)
        numspikes = length(spike_times_thresholded{n});
        allspikes = [repmat(n-1,numspikes,1) spike_times_thresholded{n} spike_amps_thresholded{n}];
    end
    allspikes = sortrows(allspikes, 2);

    % spike_templates.npy - [nSpikes, ] uint32 vector specifying the identity of the template that was used to extract each spike
    writeNPY(uint32(allspikes(:,1)), filedir + "/spike_templates.npy");

    % amplitudes.npy - [nSpikes, ] double vector with the amplitude scaling factor that was applied to the template when extracting that spike
    writeNPY(allspikes(:,3), filedir + "/amplitudes.npy");

    % spike_times.npy - [nSpikes, ] uint64 vector giving the spike time of each spike in samples. To convert to seconds, divide by sample_rate from params.py.
    writeNPY(uint64(round(allspikes(:,2))), filedir + "/spike_times.npy");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SPIKE WAVEFORM/TEMPLATE INFO
    % templates.npy - [nTemplates, nTimePoints, nTempChannels] single matrix giving the template shapes on the channels given in templates_ind.npy
    %   First, collate all templates into one huge array.
    %   - First dimension is template number
    %   - Second is time point
    %   - Third is channel number
    templates = [];
    for n=1:length(final_waveforms)
        templates(n,:,:) = final_waveforms{n};
    end
    writeNPY(templates, filedir + "/templates.npy");

    % templates_ind.npy - [nTemplates, nTempChannels] double matrix specifying the channels on which each template is defined. In the case of Kilosort templates_ind is just the integers from 0 to nChannels-1, since templates are defined on all channels.
    %   (We can just do 0 to nChannels-1)
    templates_ind = 0:(nchan-1);
    templates_ind = repmat(templates_ind, length(final_waveforms), 1);
    writeNPY(templates_ind, filedir + "/templates_ind.npy");

    % similar_templates.npy - [nTemplates, nTemplates] single matrix giving the similarity score (larger is more similar) between each pair of templates
    %   (We'll use the correlation for this. Flatten each template into a
    %   column vector, then get the correlation matrix)
    flattened_templates = [];
    for n=1:length(final_waveforms)
        flattened_templates(:,n) = final_waveforms{n}(:);
    end
    template_similarity = corr(flattened_templates);
    writeNPY(template_similarity, filedir + "/similar_templates.npy");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLUSTER GROUPS
    % spike_clusters.npy - [nSpikes, ] int32 vector giving the cluster identity of each spike. This file is optional and if not provided will be automatically created the first time you run the template gui, taking the same values as spike_templates.npy until you do any merging or splitting.
    %% FOR NOW, just do nothing and let it auto-create this file

    % cluster_groups.csv - comma-separated value text file giving the "cluster group" of each cluster (0=noise, 1=MUA, 2=Good, 3=unsorted)
    %% NOTE - Kilosort doesn't even create this file, so neither will we

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FEATURE STUFF
    % pc_features.npy - [nSpikes, nFeaturesPerChannel, nPCFeatures] single matrix giving the PC values for each spike. The channels that those features came from are specified in pc_features_ind.npy. E.g. the value at pc_features[123, 1, 5] is the projection of the 123rd spike onto the 1st PC on the channel given by pc_feature_ind[5].
    %  We will have to reconstruct this using a per-channel PCA with the CBP
    %  "snippets". For now, try saying there are 0 PC's
    pc_features = zeros(length(spike_times_thresholded), 0, 0);
    writeNPY(pc_features, filedir + "/pc_features.npy");

    % pc_feature_ind.npy - [nTemplates, nPCFeatures] uint32 matrix specifying which pcFeatures are included in the pc_features matrix.
    pc_feature_ind = uint32(zeros(length(final_waveforms), 0));
    writeNPY(pc_feature_ind, filedir + "/pc_feature_ind.npy");

    % template_features.npy - [nSpikes, nTempFeatures] single matrix giving the magnitude of the projection of each spike onto nTempFeatures other features. Which other features is specified in template_feature_ind.npy
    %   Just leaving blank for now...
    template_features = zeros(length(spike_times_thresholded), 0);
    writeNPY(template_features, filedir + "/template_features.npy");

    % template_feature_ind.npy - [nTemplates, nTempFeatures] uint32 matrix specifying which templateFeatures are included in the template_features matrix.
    %   Just leaving blank for now...
    template_feature_ind = zeros(length(final_waveforms), 0);
    writeNPY(template_feature_ind, filedir + "/template_feature_ind.npy");

end
