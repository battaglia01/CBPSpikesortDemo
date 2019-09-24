% removes a tagged object from the TagManager object stored in the figure's
% appdata.
% "item" can be an item object or a string denoting its tag name.
% UnregisterTag(item)
function UnregisterTag(item)
    f = GetCalibrationFigure;
    
    if isa(item, "string") || isa(item, "char")
        tname = item;
    else
        tname = get(item, "Tag");
    end
    
    TagManager = getappdata(f, "TagManager");
    
    % if TagManager is empty, just return
    if isempty(TagManager)
        return;
    end
    
    % if TagManager has no "tags" subobject, also return
    if ~isfield(TagManager, "tags")
        item = [];
        return;
    end
    
    % if we've gotten this far, first get the tagged item,
    % remove it from the type subobject, and then remove it from the tags
    % subobject
    item = getfield(TagManager.tags, tname);
    itemtype = get(item, "Type");
    
    % remove from type subobject
    TagManager = setfield(TagManager, itemtype, ...
        rmfield(getfield(TagManager,itemtype), tname));
    
    % remove from tags subobject
    TagManager.tags = rmfield(TagManager.tags, tname);
    
    % store it again
    setappdata(f, "TagManager", struct(TagManager));
end