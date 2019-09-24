function CBPStageList
    global CBPInternals;
    displen = 36;       % number of columns

    %display names, and categories
    currcategory = [];

    fprintf('\n**STAGE LIST**');
    for n=1:length(CBPInternals.stages)
        currname = char(CBPInternals.stages{n}.name);
        nextname = char(CBPInternals.stages{n}.next);

        %only write a new category header if the category has changed
        if ~isequal(CBPInternals.stages{n}.category, currcategory)
            currcategory = CBPInternals.stages{n}.category;
            fprintf(['\n\n  ' currcategory ':']);
        end
        fprintf(['\n  * ' currname]);

        %write arrows to indicate current/next stage
        if CBPInternals.mostrecentstage.stagenum == n
            fprintf(['\t<' repmat('-',1,displen-4*floor((length(currname)/4))-1) '  You just finished here']);
        elseif isequal(char(CBPInternals.mostrecentstage.nextfun), currname)
            fprintf(['\t<' repmat('=',1,displen-4*floor((length(currname)/4))-1) '  This stage is next']);
        end
    end
    fprintf('\n');
end
