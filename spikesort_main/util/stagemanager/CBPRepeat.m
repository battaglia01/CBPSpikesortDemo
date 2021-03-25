function CBPRepeat
    global CBPInternals;
    oldstage = CBPInternals.most_recent_stage.name;
    CBPStage(oldstage);
end
