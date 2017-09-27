<<<<<<< HEAD
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
=======
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
>>>>>>> 61a3b0d36e8cdf1210fb7f305aba3d99880c1cdc
end