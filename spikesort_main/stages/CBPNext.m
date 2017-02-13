function CBPNext(varargin)
    global nextstage;
    if(nargin > 0)
        oldstage = nextstage;
        nextstage = varargin{1};
        if(~isempty(oldstage))
            fprintf('  Finished stage: %s.\n', oldstage);
        end
        fprintf('  Current data is in "dataobj", current params in "params".\n'); 
        fprintf('  Next stage is:\n\n    %s\n\n',nextstage)
        fprintf('  Type "CBPNext" in debugger menu to proceed\n');
        fprintf('  Or, manually type a previous stage to go back\n');
    else
        eval(nextstage);
end