% Reads raw data from a file, unserializes it, and converts to double.
%
% example: out = UnserializeRawDataFromFile("filename.dat", "bit16", 4);
%
% function out = UnserializeRawDataFromFile(filename, bittype, numchannels)
function out = UnserializeRawDataFromFile(filename, bittype, numchannels)
    f = fopen(filename, 'r');
    datatype = bittype + "=>double";
    out = fread(f, datatype);
    %%@ NOTE: below we use the convention, for now, that each raw_data channel is a row
    out = reshape(out, numchannels, []);
end