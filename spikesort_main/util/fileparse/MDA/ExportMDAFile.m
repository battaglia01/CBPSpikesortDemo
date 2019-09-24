% Exporter that writes the current CBP results to the MDA format, as used
% in MountainSort, SpikeForest, etc.
%
% This is basically the same as the raw format, but with a header stating
% the bit rate, number of channels, data type, etc.

function ExportMDAFile(filename)
    global CBPdata params;

    % let user know about folder
    waitfor(msgbox("You have chosen to export to MDA format. Note that this " + ...
                   "exporter *only* saves the raw/filtered/whitened data, " + ...
                   "and not any of the clustering or CBP results. " + ...
                   "Filtered/whitened data will only be saved if the relevant " + ...
                   "stage has been done.", ...
                   "Exporting to MDA.", "help", "modal"));
               
    % create some convenient local variables
    [dir, name, ext] = fileparts(filename);
    fileprefix = dir + "/" + name;
    
    % Save raw data
    if isfield(CBPdata, "rawdata")
        writedata(fileprefix + "_raw.mda", CBPdata.rawdata);
    end
    if isfield(CBPdata, "filtering")
        writedata(fileprefix + "_filt.mda", CBPdata.filtering);
    end
    if isfield(CBPdata, "whitening")
        writedata(fileprefix + "_filtwhite.mda", CBPdata.whitening);
    end
end

% this writes the data given a filename and dataobj (e.g. CBPdata.rawdata
% or CBPdata.filtering or etc)
function writedata(filename, dataobj)
    % open file
    f = fopen(filename,"w");
    
    % write sample data format identifier
    fwrite(f, -7, "int32");     % -7 = double format
    
    % write number of bytes per sample
    fwrite(f, 8, "int32");      % 8 = 8 bytes per sample
    
    % this is a 2-dimensional array. dimension #1 is channel, #2 is sample
    fwrite(f, 2, "int32");
    
    % write dimension #1 length (i.e., number of channels)
    fwrite(f, dataobj.nchan, "int32");
    
    % write dimension #2 length (i.e., number of samples)
    fwrite(f, dataobj.nsamples, "int32");
    
    % now write the data, in "interleaved-sample" format.
    % i.e.: [samp1ch1 samp1ch2 ... samp1chN samp2ch1 samp2ch2 ... samp2chN]
    outdata = reshape(dataobj.data, [], 1);
    fwrite(f, outdata, "double");
    
    % now close
    fclose(f);
end