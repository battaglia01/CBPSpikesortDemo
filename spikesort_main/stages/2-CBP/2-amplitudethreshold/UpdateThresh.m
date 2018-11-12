% Update thresholds
function UpdateThresh(i, f)
    global dataobj;

    % First check that thresholds have actually changed
    newthresh = getappdata(f, ['imline_pos_' num2str(i)]);
    oldthresh = getappdata(f, 'amp_thresholds');
    oldthresh = oldthresh(i);
    if newthresh == oldthresh
        return;
    end

    % If we've made it this far, first thing to do is
    % disable the status bar and clear stale tabs
    DisableCalibrationStatus;
    ampstage = GetStageFromName('AmplitudeThreshold');
    ClearStaleTabs(ampstage.next);

    threshsts = getappdata(f, 'threshspiketimes');
    sts       = getappdata(f, 'spiketimes');
    amps      = getappdata(f, 'spikeamps');

    % Calculate new threshed sts
    threshsts{i} = sts{i}(amps{i} > newthresh);

    % Plot
    plotACorr(threshsts, i);
    n = length(threshsts);
    for j = 1:n
        if i==j
            continue;
        end
        plotXCorr(threshsts, i, j);
    end

    ShowGroundTruthEval(threshsts, f);

    % Save new threshes and threshed spiketimes
    setappdata(f, 'threshspiketimes', threshsts);
    amp_thresholds = getappdata(f, 'amp_thresholds');
    amp_thresholds(i) = newthresh;
    dataobj.CBPinfo.amp_thresholds = amp_thresholds;
    setappdata(f, 'amp_thresholds', amp_thresholds);

    %Done! Reset the status bar to AmplitudeThreshold
    SetCalibrationStatusStage(GetStageFromName('AmplitudeThreshold'));
end
