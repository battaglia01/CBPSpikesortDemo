% Simple exporter that just writes the current raw electrode data, as well
% as the filtered and/or whitened data (if it exists), to a .dat file.
% This file is scaled so that the Linf norm is 1, and then is saved as an
% int16. The data is serialized channel-first - so that first, you get
% [t0ch0, t0ch1, t0ch2, ..., t0chN, t1ch0, t1ch1, t1ch2 ...].
%
% This is mostly for exporting the results of the simulator for comparison
% with other spike sorters. In particular, we save as int16 for
% compatibility with klusta, which seems to expect this.

function ExportRawDataFile(filename)
    global CBPdata params;

    % let user know about folder
    waitfor(msgbox("You have chosen to export to the raw data format. Note that this " + ...
                   "exporter *only* saves the raw/filtered/whitened data, " + ...
                   "and not any of the clustering or CBP results. " + ...
                   "Filtered/whitened data will only be saved if the relevant " + ...
                   "stage has been done.", ...
                   "Exporting Raw DAT.", "help", "modal"));
               
    % create some convenient local variables
    [dir, name, ext] = fileparts(filename);
    fileprefix = dir + "/" + name;
    
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
end

% this writes the data given a filename and dataobj (e.g. CBPdata.raw_data
% or CBPdata.filtering or etc)
function writedata(filename, dataobj)
    % open file
    f = fopen(filename,"w");
    
    % now serialize and scale the data so that the max value is +/- 32767,
    % and convert to int16
    %%@ eh, sure, should probably make it so the max negative value is
    %%@ really -32768, but whatever.
    outdata = reshape(dataobj.data, [], 1);
    outdata = outdata / norm(outdata, "Inf") * 32767;
    outdata = int16(round(outdata));
    % now write the data, in "interleaved-sample" format.
    % i.e.: [samp1ch1 samp1ch2 ... samp1chN samp2ch1 samp2ch2 ... samp2chN]
    
    fwrite(f, outdata, "int16");
    
    % now close
    fclose(f);
end