function RegisterScrollAxes(ax)
global CBPdata params CBPInternals;
    if ~isfield(CBPInternals,'scrollaxes')
        CBPInternals.scrollaxes=[gobjects(0)];    %creates empty graphics array
    end

    %is it already in there?
    alreadyinthere=false;
    for n=1:length(CBPInternals.scrollaxes)
        if isequal(ax,CBPInternals.scrollaxes(n));
            alreadyinthere=true;
            break;
        end
    end
    if ~alreadyinthere
        CBPInternals.scrollaxes(end+1) = ax;
    end
    UpdateScrollAxes;
end
