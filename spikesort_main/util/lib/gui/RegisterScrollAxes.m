function RegisterScrollAxes(ax)
global dataobj params cbpglobals;
    if ~isfield(cbpglobals,'scrollaxes')
        cbpglobals.scrollaxes=[gobjects(0)];    %creates empty graphics array
    end
    
    %is it already in there?
    alreadyinthere=false;
    for n=1:length(cbpglobals.scrollaxes)
        if isequal(ax,cbpglobals.scrollaxes(n));
            alreadyinthere=true;
            break;
        end
    end
    if ~alreadyinthere
        cbpglobals.scrollaxes(end+1) = ax;
    end
    UpdateScrollAxes;
end