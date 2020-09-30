% Opens up a dialog to export a file.
function ExportFileDialog
    global CBPdata params CBPInternals;
    try
        % Open file dialog
        filterspec = {};
        for n=1:length(CBPInternals.filetypes.export)
            filterspec{n,1} = char(CBPInternals.filetypes.export{n}.ext);
            filterspec{n,2} = char(CBPInternals.filetypes.export{n}.desc + ...
                              " (" + filterspec{n,1} + ")");
        end

        [file,path,indx] = uiputfile(filterspec, 'Export Dataset');

        % If they hit cancel, just return
        if file == 0
            return
        end

        filename = fullfile(path,file);

        fprintf("\nWriting to %s (%s)...\n", filename, ...
                CBPInternals.filetypes.export{indx}.desc);

        % Once we have the file info, call the subparser,
        % and run initialize session (pass filename).
        % Also disable calibration status if we're in calibration mode
        if params.plotting.calibration_mode
            DisableCalibrationStatus;
        end
        SubParserFunc = CBPInternals.filetypes.export{indx}.funchandle;
        SubParserFunc(filename);
        fprintf("Done!\n");
        EnableCalibrationStatus;
    catch err
        EnableCalibrationStatus;    % make sure we re-enable no matter what
        errordlg(sprintf("There was an error while writing to the file.\n" + ...
                         "\n" + ...
                         "Error message is below:\n" + ...
                         "===\n%s\n" + ...
                         "===\n\nMore detail in the command window.", ...
                         err.message), "Processing Error", "modal");
        rethrow(err);
    end
end
