function bool = haveIPT()
v = ver();
bool = any(strcmp('Image Processing Toolbox', {v.Name}));