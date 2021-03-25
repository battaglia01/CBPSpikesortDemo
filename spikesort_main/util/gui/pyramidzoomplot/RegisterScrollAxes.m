function RegisterScrollAxes(ax)
global CBPdata params CBPInternals;
    if ~isfield(CBPInternals,'pyramid_scroll_axes')
        CBPInternals.pyramid_scroll_axes=[gobjects(0)];    %creates empty graphics array
    end

    %is it already in there?
    alreadyinthere=false;
    for n=1:length(CBPInternals.pyramid_scroll_axes)
        if isequal(ax,CBPInternals.pyramid_scroll_axes(n));
            alreadyinthere=true;
            break;
        end
    end
    if ~alreadyinthere
        CBPInternals.pyramid_scroll_axes(end+1) = ax;
    end
    UpdateScrollAxes;
end
