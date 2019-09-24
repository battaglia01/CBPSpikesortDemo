% Basic exporter that writes the current CBP results to a mat file, with
% `CBPdata` and `params` objects.

function ExportCBPFile(filename)
    global CBPdata params;
    save(filename, 'CBPdata', 'params');
end