% Converts a parameter to a string
function out=ConvertParamToStr(in)
    if isequal(class(in), 'double')
        if length(in) > 1
            out = '[';
            for n=1:length(in)
                out = [out num2str(in(n)) ' '];
            end
            out = [out(1:end-1) ']'];
        else
            out = num2str(in);
        end
        return;
    end
    out=toString(in);
end