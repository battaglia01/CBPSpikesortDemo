% Returns a handle to the params status bar.
% If it doesn't exist, create it.

function h = GetParamsStatus
    global params;

    h = LookupTag('params_sb');
    if isempty(h) || ~isvalid(h)
        h = CreateParamsStatus;
    end
end
