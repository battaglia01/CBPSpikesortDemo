<<<<<<< HEAD
function bool = haveIPT()
v = ver();
=======
function bool = haveIPT()
v = ver();
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
bool = any(strcmp('Image Processing Toolbox', {v.Name}));