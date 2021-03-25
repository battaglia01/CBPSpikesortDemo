% adds a tagged object to the TagManager object stored in the figure's
% appdata.
%
% RegisterTag(item)
function RegisterTag(item)
    f = GetCalibrationFigure;
    tname = get(item, "Tag");
    TagManager = getappdata(f, "TagManager");
    
    % make sure it's a struct
    if ~isstruct(TagManager)
        TagManager = struct(TagManager);
    end
    
    % stupid MATLAB thing - make sure TagManager is non-empty so we can
    % address
    if isempty(TagManager)
        TagManager(1).dummy = 1;
    end
    
    % make sure "tags" subobject exists
    if ~isfield(TagManager, "tags")
        TagManager.tags = [];
    end
    
    % make sure item type subobject exists
    itemtype = get(item, "Type");
    if ~isfield(TagManager, itemtype)
        TagManager = setfield(TagManager, itemtype, []);
    end
    
    % add tag to "tags" subobject and to type subobject
    TagManager.tags = setfield(TagManager.tags, tname, item);
    TagManager = setfield(TagManager, itemtype, ...
        setfield(getfield(TagManager,itemtype), tname, item));
    
    % lastly, remove stupid MATLAB dummy thing
    if isfield(TagManager, "dummy")
        TagManager = rmfield(TagManager, "dummy");
    end
    
    % store again
    setappdata(f, "TagManager", TagManager);
end