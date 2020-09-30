% This initializes the session after the file has been parsed.
% We need to pass the filename to this function as well.
%
% The index is the entry `n` in CBPInternals.import{n} that matches the file
% being parsed and loaded
function InitializeSession(filename)
    global CBPdata params CBPInternals;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add extra parameters
    % At this point, the file is loaded. There should be "CBPdata"
    % and "params" variables in the global workspace.

    % Now add in whatever parameters are missing
    FillInDefaultParameters;

    % Get experiment label. Use existing one by default, or filename if
    % there is no existing one
    if isfield(CBPdata, 'experimentname')
        defaultexpname = char(CBPdata.experimentname);
    else
        % set up filename as default
        filenameindex = max([strfind(filename,'/') strfind(filename,'\')]);
        if isempty(filenameindex)
            filenameindex = 0;
        end
        defaultexpname = char(filename(filenameindex+1:end));
    end

    experimentname = inputdlg('Please enter an experiment label to use in identifying this session:', ...
                              'Experiment Label', 1, {char(defaultexpname)});
    if isempty(experimentname) || isempty(experimentname{1})
        experimentname = defaultexpname;
    else
        experimentname = experimentname{1};
    end

    fprintf('\nUsing experiment label: "%s"\n', experimentname);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Validate parameters
%%@ maybe spin off to another ValidateParameters.m thing if need be

% Validate number of channels <= 4
    % If there are too many channels, ask them to narrow it down
    % do this as a loop until they enter valid input
    while isfield(CBPInternals, 'skipmaxchannelmessage') && ...
          CBPInternals.skipmaxchannelmessage && ...
          size(CBPdata.rawdata.data, 1) > 4
        numchans = size(CBPdata.rawdata.data, 1);

        % MATLAB goofy multiline string stuff
        message = "WARNING: This file contains "+numchans+" channels, more than the recommended amount of 4.\n" + ...
                  "\n" + ...
                  "Please enter the channels you want to keep below, as a 1D MATLAB array.\n" + ...
                  "Note that MATLAB begins counting indices at 1, rather than 0.\n" + ...
                  "\n" + ...
                  "Examples:\n" + ...
                  "   [1 2 3 4]\n" + ...
                  "   1:"+numchans;
        message = sprintf(message); % needed to escape the \n's

        % dialog that gets the channel subset they want.
        newchans = inputdlg(message, 'Channel Subset', 1, {'[1 2 3 4]'});

        % make sure array isn't malformed. if it is, do the loop again
        try
            newchans = double(eval([newchans{1}]));
            assert(min(size(newchans)) == 1);
        catch
            e = errordlg("Invalid array. Please enter an array of " + ...
                     "values between 1 and " + numchans + ".", "Error!", "modal");
            uiwait(e);
            continue;
        end

        % make sure array values are in bounds. if not, do the loop again
        try
            assert(min(newchans) >= 1 && ...
            max(newchans) <= size(CBPdata.rawdata.data, 1));
            CBPdata.rawdata.data = CBPdata.rawdata.data(newchans,:);
        catch
            e = errordlg("Invalid array values. Please make sure this is a " + ...
                         "1D array and that all values are between 1 and " + ...
                         numchans + ".", "Error!", "modal");
            uiwait(e);
            continue;
        end

        % if we got this far, none of the errors were raised, so just break
        break;
    end
    CBPInternals.skipchannelmessage = false;

% Validate number of initial waveform clusters is <= cells to plot
% Don't have them change it, just give them a note
    % If there are too many clusters, tell them only some will be plotted
    if params.clustering.num_waveforms > length(CBPInternals.cells_to_plot)
        % MATLAB goofy multiline string stuff
        message = "NOTE: These parameters call for " + ...
                  params.clustering.num_waveforms + " starting clusters. " + ...
                  "The default setting in this program is to plot the " + ...
                  "first " + length(CBPInternals.cells_to_plot) + " clusters " + ...
                  "in the calibration window." + ...
                  newline + ...
                  newline + ...
                  "  * You can change the cells being plotted by clicking " + ...
                  "on the ""Cell Plot Info..."" button in the calibration window." + ...
                  newline + ...
                  "  * You can also change the number of starting clusters " + ...
                  "by changing params.clustering.num_waveforms." + ...
                  newline + ...
                  newline + ...
                  "Note that every cell is still being calculated internally. " + ...
                  "This setting only represents which cells are being plotted " + ...
                  "graphically for calibration and diagnostic purposes. " + ...
                  "Note that you can change the cells being plotted midway " + ...
                  "through the program to compare different ones." + ...
                  newline;
        m = msgbox(message, 'Clusters being plotted', 'modal');
        uiwait(m);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finish loading filename, data, etc

    % Set filename, channels, samples, etc from the above
    CBPdata.filename = filename;
    CBPdata.experimentname = experimentname;
    CBPdata.rawdata.nchan = size(CBPdata.rawdata.data, 1);
    CBPdata.rawdata.nsamples = size(CBPdata.rawdata.data, 2);

    % If no ground truth, just make a blank one
    if ~isfield(CBPdata, 'groundtruth')
        CBPdata.groundtruth = [];
    end

    % Order properly
    fields = setdiff(fieldnames(CBPdata), {'filename', 'experimentname'});
    CBPdata = orderfields(CBPdata, {'filename', 'experimentname', fields{:}});

    % Change zoomlevel so we get the first ~2-3 seconds
    params.plotting.zoomlevel = ...
        floor(log2(CBPdata.rawdata.nsamples*CBPdata.rawdata.dt/2)+1);

    % Print our results and exit
    fprintf('\n');
    fprintf('  Loaded data contains %d sec (%.1f min) of voltage data at %.1f kHz on %d channel(s).\n', ...
		round(CBPdata.rawdata.nsamples*CBPdata.rawdata.dt), ...
        (CBPdata.rawdata.nsamples*CBPdata.rawdata.dt/60), ...
        1/(CBPdata.rawdata.dt*1000), ...
        CBPdata.rawdata.nchan);

    if (CBPdata.rawdata.dt > 1/5000)
        warning('Sampling rate is %.1f kHz, but recommended minimum is 5kHz', ...
                1/(1000*CBPdata.rawdata.dt));
    end
end
