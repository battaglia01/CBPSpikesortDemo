% gets a tagged object fromthe TagManager object stored in the figure's
% appdata. Returns [] if nothing is available.
%
% item = LookupTag(tag)
function item = LookupTag(tname)
    f = GetCalibrationFigure;
    TagManager = getappdata(f, "TagManager");
    
    % if TagManager is empty, just return
    if isempty(TagManager)
        item = [];
        return;
    end
    
    % if TagManager has no "tags" subobject, also return
    if ~isfield(TagManager, "tags")
        item = [];
        return;
    end
    
    % if we've gotten this far, check the tags subobject
    if isfield(TagManager.tags, tname)
        item = getfield(TagManager.tags, tname);
    else
        item = [];
    end
end