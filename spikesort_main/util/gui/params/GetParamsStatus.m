% Returns a handle to the params status bar.
% If it doesn't exist, create it.

function h = GetParamsStatus
    global params;
    
    h = findobj('Tag','params_sb');
    if isempty(h)
        h = CreateParamsStatus;
    end
end