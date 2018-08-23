function StageInstructions
    global cbpglobals;
    fprintf('\n');
    fprintf('  Current data is in "dataobj", current params in "params".\n');
    fprintf('  Next stage is:\n    %s\n\n', char(cbpglobals.stages{cbpglobals.currstageind}.nextfun))
    fprintf('  Type "CBPNext" below to proceed\n');
    fprintf('  Type "CBPRepeat" to repeat current stage\n');
    fprintf('  Or, type "CBPStageList" to see a list of all cbpglobals.stages\n');
    fprintf('  You can go directly to a stage by typing it manually.\n\n');
    fprintf('  To reset all parameters and begin again, type "CBPReset"\n');
    fprintf('\n');
end
