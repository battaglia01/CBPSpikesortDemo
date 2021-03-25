function CBPReset
	global CBPdata params CBPInternals;
    % close all and delete globals
    close all hidden;
    clear global CBPdata params CBPInternals dialogresult;
end
