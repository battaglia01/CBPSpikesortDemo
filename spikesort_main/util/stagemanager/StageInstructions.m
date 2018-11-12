function StageInstructions
    global cbpglobals;
    fprintf('\n');
    fprintf('  Current data is in "dataobj", current params in "params".\n');
    
    if cbpglobals.stages{cbpglobals.currstagenum}.next
        fprintf('  Next stage is:\n    %s\n\n', cbpglobals.stages{cbpglobals.currstagenum}.next)
    else
        fprintf('  This is the last stage!\n');
    end
    
    if cbpglobals.stages{cbpglobals.currstagenum}.showreview
        fprintf('  Type "CBPReview" below to go to Post-Analysis!\n');
        fprintf('  Or type "CBPNext" below to do another iteration of CBP\n');
        fprintf('\n');
    elseif cbpglobals.stages{cbpglobals.currstagenum}.next
        fprintf('  Type "CBPNext" below to proceed\n');
    end
    
    fprintf('  Type "CBPRepeat" to repeat current stage\n');
    fprintf('  Or, type "CBPStageList" to see a list of all cbpglobals.stages\n');
    fprintf('  You can go directly to a stage by typing it manually.\n\n');
    fprintf('  To reset all parameters and begin again, type "CBPReset"\n');
    fprintf('\n');
end
