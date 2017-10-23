function CBPNext(varargin)
    global oldstage nextstage;
    if(nargin > 0)
        nextstage = varargin{1};
        
        fprintf('\n');
        fprintf('  Current data is in "dataobj", current params in "params".\n');
        fprintf('  Next stage is:\n    %s\n\n',nextstage)
        fprintf('  Type "CBPNext" below to proceed\n');
        fprintf('  Type "CBPRepeat" to repeat current stage\n');
        fprintf('  Or, type "CBPStages" to see a list of all stages\n');
        fprintf('  You can go directly to a stage by typing it manually.\n');
        fprintf('\n');
    else
        oldstage = nextstage;
        eval(nextstage);
end