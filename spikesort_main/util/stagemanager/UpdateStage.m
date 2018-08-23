function UpdateStage(newstage, clearcurr)
    global cbpglobals;
    
    if nargin == 1
        clearcurr = true;
    end

    %find current stage and then clear all others
    ind = 0;
    found = false;
    for n=1:length(cbpglobals.stages)
        if isequal(cbpglobals.stages{n}.currfun, newstage)
            ind = n;
            found = true;
            
            %skip the first replot if clearcurr is set
            if ~clearcurr
                continue;
            end
        end
        
        if found & ~isempty(cbpglobals.stages{n}.plotfun)
            cbpglobals.stages{n}.plotfun('disable');    %clear display
        end
    end
    pause(.001); %needed to make sure everything clears
    cbpglobals.currstageind = ind;
    UpdateScrollAxes;
end
