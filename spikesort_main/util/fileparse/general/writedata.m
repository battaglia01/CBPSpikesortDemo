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