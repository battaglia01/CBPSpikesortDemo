function TabChanged(tabgroup, eventData)
    global CBPInternals;
    % first, check if we're disabled. If we are, un-change the tab and exit
    if ~getappdata(tabgroup, "Enabled")
        tabgroup.SelectedTab = eventData.OldValue;
        drawnow;
        pause(0.01);
        return;
    end
    
    % if we got this far then we're good to go with the change.
    % first, update the internal "currselectedtabstage"
    newstageobj = getappdata(eventData.NewValue, 'stageobj');
    CBPInternals.currselectedtabstage = newstageobj;

    % now set the new calibration status
    SetCalibrationStatusStage(newstageobj);

    % Then, if "needsreplot" is set in the current stage, replot and reset.
    % Note this updates the true stage object, since stages are subclasses
    % of handle
    if newstageobj.needsreplot
        CBPStagePlot(newstageobj);
        CBPInternals.currselectedtabstage.needsreplot = false;
        newstageobj.needsreplot = false;
    end
end
