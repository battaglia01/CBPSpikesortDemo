function StageInstructions
    global stages currstageind;
    fprintf('\n');
    fprintf('  Current data is in "dataobj", current params in "params".\n');
    fprintf('  Next stage is:\n    %s\n\n', char(stages{currstageind}{2}))
    fprintf('  Type "CBPNext" below to proceed\n');
    fprintf('  Type "CBPRepeat" to repeat current stage\n');
    fprintf('  Or, type "CBPStageList" to see a list of all stages\n');
    fprintf('  You can go directly to a stage by typing it manually.\n');
    fprintf('\n');
end