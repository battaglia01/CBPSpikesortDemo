function CBPNext
    global CBPInternals;

    if ~isfield(CBPInternals, 'raninit') || CBPInternals.raninit == false
        BasicSetup;
    elseif isempty(CBPInternals.mostrecentstage)
        CBPStage(CBPInternals.stages{1}.name);
    else
        assert(~isempty(CBPInternals.mostrecentstage.next), ...
            'ERROR: This is the last stage!');
        CBPStage(CBPInternals.mostrecentstage.next);
    end
end
