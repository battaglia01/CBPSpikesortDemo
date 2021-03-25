% Parses a Neuroscope .xml file.

function ParseNeuroscopeFile(filename)
    global CBPdata params CBPInternals
    
    % first, make sure associated dat file exists
    datname = strrep(filename, ".xml", ".dat");
	assert(isfile(datname), "ERROR: associated DAT file at " + datname + ...
                            "' doesn't exist!");
    
    %open xml file and parse as struct
    xml = xml2struct(filename);
    
    % get parameters needed to parse .dat file
    nBits = str2num(xml.parameters.acquisitionSystem.nBits.Text);
    nChannels = str2num(xml.parameters.acquisitionSystem.nChannels.Text);
    samplingRate = str2num(xml.parameters.acquisitionSystem.samplingRate.Text);
    voltageRange = str2num(xml.parameters.acquisitionSystem.voltageRange.Text);
    amplification = str2num(xml.parameters.acquisitionSystem.amplification.Text);
    offset = str2num(xml.parameters.acquisitionSystem.offset.Text);
    
    % read the dat file with this info and deserialize
    datatype = "bit"+nBits;
    raw = UnserializeRawDataFromFile(datname, datatype, nChannels);
    
    % convert to correct voltage range. Note that voltageRange is the total
    % peak-to-peak range, so we scale by half
    %%@ need clarification on "voltage range" vs "amplification"
    %%@ also need clarification on if we subtract or add offset
    raw = raw * (voltageRange/2 - offset)/amplification;
    
    % now add everything to CBPdata
    CBPdata.raw_data.data = raw;
    CBPdata.raw_data.dt = 1/samplingRate;
    CBPdata.nchan = nChannels;
    CBPdata.nsamples = size(raw,2);
end 