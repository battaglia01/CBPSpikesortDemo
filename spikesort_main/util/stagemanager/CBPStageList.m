function CBPStageList
    global cbpglobals;
    displen=36;

    %display names, and categories
    currcategory = [];
    for n=1:length(cbpglobals.stages)
        currname = char(cbpglobals.stages{n}.currfun);
        nextname = char(cbpglobals.stages{n}.nextfun);

        %only write a new category header if the category has changed
        if ~isequal(cbpglobals.stages{n}.category, currcategory)
            currcategory = cbpglobals.stages{n}.category;
            fprintf(['\n\n  ' currcategory ':']);
        end
        fprintf(['\n  * ' currname]);

        %write arrows to indicate current/next stage
        if cbpglobals.currstageind == n
            fprintf(['\t<' repmat('-',1,displen-4*floor((length(currname)/4))-1) '  You just finished here']);
        elseif isequal(char(cbpglobals.stages{cbpglobals.currstageind}.nextfun), currname)
            fprintf(['\t<' repmat('=',1,displen-4*floor((length(currname)/4))-1) '  This stage is next']);
        end
    end
    fprintf('\n');
end
