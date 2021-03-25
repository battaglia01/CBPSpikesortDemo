function CBPNext
    global CBPInternals;

    if ~isfield(CBPInternals, 'raninit') || CBPInternals.raninit == false
        BasicSetup;
    elseif isempty(CBPInternals.most_recent_stage)
        CBPStage(CBPInternals.stages{1}.name);
    else
        assert(~isempty(CBPInternals.most_recent_stage.next), ...
            'ERROR: This is the last stage!');
        CBPStage(CBPInternals.most_recent_stage.next);
    end
end
