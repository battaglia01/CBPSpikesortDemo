% Converts a parameter to a string
function out = ConvertParamToStr(in)
    if isequal(class(in), 'double')
        if numel(in) > 1
            out = '[';
            for r=1:size(in,1)
                for c=1:size(in,2)
                    out = [out num2str(in(r,c)) ' '];
                end
                if r~=size(in,1)
                    out = [out(1:end-1) ';'];
                end
            end
            out = [out(1:end-1) ']'];
        else
            out = num2str(in);
        end
        return;
    end
    out = toString(in);
end