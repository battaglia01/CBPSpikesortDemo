% Parses a raw .dat file.
%%@ note - may want to also do the order where it's all samples on the same
%%@ channel first
function ParseRawDataFile(filename)
    global CBPdata params CBPInternals
    
    % first, make sure associated dat file exists
    datname = strrep(filename, ".xml", ".dat");
	assert(isfile(datname), "ERROR: associated DAT file at " + datname + ...
                            "' doesn't exist!");
    
    % now ask about number of channels
    numchannels = inputdlg('Please enter the number of channels:', ...
                            'Number of Channels', 1);
    numchannels = str2num(numchannels{1});

    % get sample rate
    samplerate = inputdlg('Please enter the sample rate:', ...
                            'Sample Rate', 1);
    samplerate = str2num(samplerate{1});
    
    % get number of bits
    numbits = inputdlg('Please enter the number of bits per sample:', ...
                       'Number of Bits', 1);
    numbits = str2num(numbits{1});
    
    % get signed or unsigned
    signed = questdlg("Are these bits signed or unsigned?", ...
                      "Signed bits", "Signed", "Unsigned", "Signed");
    
    if signed == "Signed"
        datatype = "bit"+numbits;
    else
        datatype = "ubit"+numbits;
    end
    
    % read the dat file with this info and deserialize
    raw = UnserializeRawDataFromFile(datname, datatype, numchannels);
    
    % now add everything to CBPdata
    CBPdata.rawdata.data = raw;
    CBPdata.rawdata.dt = 1/samplerate;
    CBPdata.nchan = numchannels;
    CBPdata.nsamples = size(raw,2);
end 