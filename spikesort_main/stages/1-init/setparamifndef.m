function setparamifndef(p_name, p_value)
    global params;
    try
        eval([p_name ';']);
    catch
        eval([p_name ' = ' p_value ';']);
    end
end